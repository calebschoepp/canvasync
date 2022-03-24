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
      notebook.background.blob.open do |template|
        orientation = pdf_orientation(template)
        Prawn::Document.generate(tempfile.path, :skip_page_creation => true, :margin => PAGE_MARGINS) do |pdf|
          (1..notebook.pages.length).each do |i|
            pdf.start_new_page :template => template, :template_page => i
            pdf.go_to_page(i)

            if i <= count_pdf_pages(template)
              # Set the transformation matrix for the page
              set_transformation_matrix(pdf, template.path)
            end

            page = notebook.pages.find_by(:number => i)
            if page && user_notebook.is_owner
              layer = page.layers.find_by(:writer => user_notebook)
              draw_layer_diffs(pdf, layer, orientation)
            elsif page
              owner_user_notebook = notebook.user_notebooks.find_by(user_id: notebook.owner)
              owner_layer = page.layers.find_by(:writer => owner_user_notebook)
              draw_layer_diffs(pdf, owner_layer, orientation)
              participant_layer = page.layers.find_by(:writer => user_notebook)
              draw_layer_diffs(pdf, participant_layer, orientation)
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

  def pdf_orientation(filename)
    pdf_reader = PDF::Reader.new(filename)
    pdf_reader.pages.first.orientation
  end

  def count_pdf_pages(pdf_file_path)
    pdf = Prawn::Document.new(:template => pdf_file_path)
    pdf.page_count
  end

  def scaled_page_dimensions
    PAGE_DIMS.map { |dim| dim * SCALING_FACTOR }
  end

  def set_transformation_matrix(pdf, filename)
    pdf_reader = PDF::Reader.new(filename)
    return if pdf_reader.pages.empty?

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

  def draw_layer_diffs(pdf, layer, orientation)
    vertical_offset = orientation == 'portrait' ? scaled_page_dimensions[1] : scaled_page_dimensions[0]
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
        red = data[1]['strokeColor'][0].to_f
        red = (red * 255).round.to_s(16).rjust(2, '0').upcase
        green = data[1]['strokeColor'][1].to_f
        green = (green * 255).round.to_s(16).rjust(2, '0').upcase
        blue = data[1]['strokeColor'][2].to_f
        blue = (blue * 255).round.to_s(16).rjust(2, '0').upcase

        pdf.stroke_color "#{red}#{green}#{blue}"
        pdf.line_width 3
        pdf.stroke
      when 'PointText'
        pdf.draw_text data[1]['content'], :at => [data[1]['matrix'][4].to_f, vertical_offset - data[1]['matrix'][5].to_f], :size => 25
      end
    end
  end
end
