require 'prawn'
require 'json'

class ExportNotebookJob < ApplicationJob
  queue_as :default

  PAGE_HEIGHT = 777

  def perform(export_id)
    export = Export.find(export_id)

    notebook = export.notebook
    user_notebook = notebook.user_notebooks.find_by(user_id: export.user_id)

    tempfile = Tempfile.new ['export', '.pdf']

    notebook.background.blob.open do |template|
      Prawn::Document.generate(tempfile.path, :skip_page_creation => true, :margin => [0, 0, 0, 0]) do |pdf|
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
            draw_layer_diffs(pdf, layer)
          elsif page
            owner_user_notebook = notebook.user_notebooks.find_by(user_id: notebook.owner)
            owner_layer = page.layers.find_by(:writer => owner_user_notebook)
            draw_layer_diffs(pdf, owner_layer)
            participant_layer = page.layers.find_by(:writer => user_notebook)
            draw_layer_diffs(pdf, participant_layer)
          end
        end
      end
    end

    export.document.attach(io: File.open(tempfile.path), filename: "#{notebook.name}.pdf")

    export.ready = true
    export.save
  end

  def count_pdf_pages(pdf_file_path)
    pdf = Prawn::Document.new(:template => pdf_file_path)
    pdf.page_count
  end

  def set_transformation_matrix(pdf, filename)
    pdf_reader = PDF::Reader.new(filename)
    return if pdf_reader.pages.empty?
    page = pdf_reader.pages.first
  
    buffer = PDF::Reader::Buffer.new(StringIO.new(page.raw_content), content_stream: true)
    parser = PDF::Reader::Parser.new(buffer)
    params = []
  
    while (token = parser.parse_token(PDF::Reader::PagesStrategy::OPERATORS))
      if token.kind_of?(PDF::Reader::Token) && PDF::Reader::PagesStrategy::OPERATORS.has_key?(token)
        operator = PDF::Reader::PagesStrategy::OPERATORS[token]
        if operator == :concatenate_matrix && params[0..3] == [1, 0, 0, -1]
          pdf.transformation_matrix(*params)
        elsif operator == :concatenate_matrix
          pdf.transformation_matrix(*params)
        else
          pdf.transformation_matrix(1, 0, 0, 1, 0, 0)
        end
        # If first token was not a concatenate_matrix operator, then do nothing.
        return
      else
        params << token
      end
    end
  end

  def draw_layer_diffs(pdf, layer)
    if layer
      layer.diffs.each do |diff|
        next unless diff.diff_type == 'tangible' && diff.visible

        data = JSON.parse(diff.data)
        case data[0]
        when 'Path'
          segments = data[1]['segments']
          if segments
            (1..(segments.length - 1)).each do |point|
              # get last point anchor
              source = [segments[point - 1][0][0].to_f, PAGE_HEIGHT - segments[point - 1][0][1].to_f]
              # get this point anchor
              dest = [segments[point][0][0].to_f, PAGE_HEIGHT - segments[point][0][1].to_f]
              # get last point handle out + last point anchor to get first bezier anchor point
              bezier1 = [source[0] + segments[point - 1][2][0].to_f, source[1] - segments[point - 1][2][1].to_f]
              # get this point handle in + this point anchor to get second bezier anchor point
              bezier2 = [dest[0] + segments[point][1][0].to_f, dest[1] - segments[point][1][1].to_f]
              pdf.curve source, dest, :bounds => [bezier1, bezier2]
            end
          end
          red = data[1]['strokeColor'][0].to_i.to_s(16).rjust(2, '0').upcase
          green = data[1]['strokeColor'][1].to_i.to_s(16).rjust(2, '0').upcase
          blue = data[1]['strokeColor'][2].to_i.to_s(16).rjust(2, '0').upcase

          pdf.stroke_color "#{red}#{green}#{blue}"
          pdf.line_width 3
          pdf.stroke
        when 'PointText'
          pdf.draw_text data[1]['content'], :at => [data[1]['matrix'][4].to_f, PAGE_HEIGHT - data[1]['matrix'][5].to_f], :size => 25
        end
      end
    end
  end
end
