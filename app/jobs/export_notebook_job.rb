require 'prawn'
require 'json'
require './app/lib/page_dimensions'

class ExportNotebookJob < ApplicationJob
  include PageDimensions
  queue_as :default

  SCALING_FACTOR = 1.5

  def perform(export_id)
    export = Export.find(export_id)

    notebook = export.notebook
    user_notebook = notebook.user_notebooks.find_by(user_id: export.user_id)

    tempfile = Tempfile.new ['export', '.pdf']

    begin
      if notebook.background.blob
        notebook.background.blob.open do |template|
          Prawn::Document.generate(tempfile.path, :skip_page_creation => true, :margin => PAGE_MARGINS) do |pdf|
            num_pdf_pages = count_pdf_pages(template)
            (1..notebook.pages.length).each do |i|
              if i <= num_pdf_pages
                pdf.start_new_page :template => template, :template_page => i
              else
                pdf.start_new_page :size => 'LETTER', :layout => :portrait
              end
              pdf.go_to_page(i)

              # default height is landscape letter size
              page_height = PAGE_DIMS[1]
              if i <= num_pdf_pages
                # Set the transformation matrix for the page
                page_height = pdf_page_height(template, i)
                set_transformation_matrix(pdf, template.path, page_height)
              else
                # otherwise set the transformation matrix for the viewport
                pdf.transformation_matrix((2.0 / 3.0), 0, 0, (2.0 / 3.0), 0, 0)
              end

              page = notebook.pages.find_by(:number => i)
              if page && user_notebook.is_owner
                layer = page.layers.find_by(:writer => user_notebook)
                draw_layer_diffs(pdf, layer, page_height)
              elsif page
                owner_user_notebook = notebook.user_notebooks.find_by(user_id: notebook.owner)
                owner_layer = page.layers.find_by(:writer => owner_user_notebook)
                draw_layer_diffs(pdf, owner_layer, page_height)
                participant_layer = page.layers.find_by(:writer => user_notebook)
                draw_layer_diffs(pdf, participant_layer, page_height)
              end
            end
          end
        end
      else
        Prawn::Document.generate(tempfile.path, :skip_page_creation => true, :margin => PAGE_MARGINS) do |pdf|
          (1..notebook.pages.length).each do |i|
            pdf.start_new_page
            pdf.go_to_page(i)

            # page height is landscape letter size
            page_height = PAGE_DIMS[1]
            pdf.transformation_matrix((2.0 / 3.0), 0, 0, (2.0 / 3.0), 0, 0)

            page = notebook.pages.find_by(:number => i)
            if page && user_notebook.is_owner
              layer = page.layers.find_by(:writer => user_notebook)
              draw_layer_diffs(pdf, layer, page_height)
            elsif page
              owner_user_notebook = notebook.user_notebooks.find_by(user_id: notebook.owner)
              owner_layer = page.layers.find_by(:writer => owner_user_notebook)
              draw_layer_diffs(pdf, owner_layer, page_height)
              participant_layer = page.layers.find_by(:writer => user_notebook)
              draw_layer_diffs(pdf, participant_layer, page_height)
            end
          end
        end
      end
    rescue StandardError => e
      puts "Rescued: #{e.inspect}"
      export.failed = true
    else
      export.document.attach(io: File.open(tempfile.path), filename: "#{notebook.name}.pdf")
      export.ready = true
    ensure
      export.save
    end
  end

  def pdf_page_height(filename, page_number)
    pdf_reader = PDF::Reader.new(filename)
    pdf_reader.page(page_number).height
  end

  def count_pdf_pages(pdf_file_path)
    pdf = Prawn::Document.new(:template => pdf_file_path)
    pdf.page_count
  end

  def color_hex(color_params)
    red = color_params[0].to_f
    red = (red * 255).round.to_s(16).rjust(2, '0').upcase
    green = color_params[1].to_f
    green = (green * 255).round.to_s(16).rjust(2, '0').upcase
    blue = color_params[2].to_f
    blue = (blue * 255).round.to_s(16).rjust(2, '0').upcase
    "#{red}#{green}#{blue}"
  end

  def set_transformation_matrix(pdf, filename, page_height)
    pdf_reader = PDF::Reader.new(filename)
    return if pdf_reader.pages.empty?

    cm_params = nil
    tm_params = nil
    File.foreach(filename) do |line|
      line = line.scrub(' ')
      params = line.split
      case params[-1]
      when 'cm'
        cm_params = Matrix[
          [params[0].to_f, params[1].to_f, 0],
          [params[2].to_f, params[3].to_f, 0],
          [params[4].to_f, params[5].to_f, 1]
        ]
      when 'Tm'
        tm_params = Matrix[
          [params[0].to_f * (2.0 / 3.0), params[1].to_f, 0],
          [params[2].to_f, params[3].to_f * (2.0 / 3.0), 0],
          [0, page_height, 1 * (2.0 / 3.0)]
        ]
      end
      if cm_params && tm_params
        transformation_matrix = tm_params * cm_params
        transformation_params = transformation_matrix.to_a
        transformation_params = [
          transformation_params[0][0],
          transformation_params[0][1],
          transformation_params[1][0],
          transformation_params[1][1],
          transformation_params[2][0],
          transformation_params[2][1]
        ]
        pdf.transformation_matrix(*transformation_params)
        return nil
      end
    end

    page = pdf_reader.pages.first

    buffer = PDF::Reader::Buffer.new(StringIO.new(page.raw_content), content_stream: true)
    parser = PDF::Reader::Parser.new(buffer)
    params = []

    while (token = parser.parse_token(PDF::Reader::PagesStrategy::OPERATORS))
      if token.is_a?(PDF::Reader::Token) && PDF::Reader::PagesStrategy::OPERATORS.key?(token)
        operator = PDF::Reader::PagesStrategy::OPERATORS[token]
        if operator == :concatenate_matrix
          params[0] = (params[0] * 1.1875)
          params[3] = (params[3] * 1.1875)
          params[5] = (params[5].to_f * (4.0 / 3.0)).round
          pdf.transformation_matrix(*params)
        else
          pdf.transformation_matrix((2.0 / 3.0), 0, 0, (2.0 / 3.0), 0, 0)
        end
        # If first token was not a concatenate_matrix operator, then do nothing.
        return
      else
        params << token
      end
    end
  end

  def draw_layer_diffs(pdf, layer, page_height)
    vertical_offset = page_height * SCALING_FACTOR
    layer&.diffs&.each do |diff|
      next unless diff.diff_type == 'tangible' && diff.visible

      data = JSON.parse(diff.data)
      case data[0]
      when 'Path'
        segments = data[1]['segments']
        if segments
          (1..(segments.length - 1)).each do |point|
            # get last point anchor
            source = [segments[point - 1][0][0].to_f, vertical_offset - segments[point - 1][0][1].to_f]
            # get this point anchor
            dest = [segments[point][0][0].to_f, vertical_offset - segments[point][0][1].to_f]
            # get last point handle out + last point anchor to get first bezier anchor point
            bezier1 = [source[0] + segments[point - 1][2][0].to_f, source[1] - segments[point - 1][2][1].to_f]
            # get this point handle in + this point anchor to get second bezier anchor point
            bezier2 = [dest[0] + segments[point][1][0].to_f, dest[1] - segments[point][1][1].to_f]
            pdf.curve source, dest, :bounds => [bezier1, bezier2]
          end
        end
        hex = color_hex(data[1]['strokeColor'])

        pdf.stroke_color hex
        pdf.line_width 3
        pdf.stroke
      when 'PointText'
        hex = color_hex(data[1]['strokeColor'])
        pdf.fill_color hex
        pdf.draw_text data[1]['content'], :at => [data[1]['matrix'][4].to_f, vertical_offset - data[1]['matrix'][5].to_f], :size => 25
      end
    end
  end
end
