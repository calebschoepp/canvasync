require 'prawn'
require 'json'

class ExportNotebookJob < ApplicationJob
  queue_as :default

  def to_hex(n)
    n.to_s(16).rjust(2, '0').upcase
  end

  def perform(export_id)
    # TODO: Actually export notebook
    export = Export.find(export_id)

    notebook = export.notebook
    user_notebook = notebook.user_notebooks.find_by(user_id: export.user_id)

    Prawn::Document.generate("export.pdf", :skip_page_creation => true, :margin => [0,0,0,0]) do
      for i in 1..notebook.pages.length
        start_new_page
        go_to_page(i)

        layer = user_notebook.layers.find(i)
        layer.diffs.each do |diff|
          if diff.diff_type == "tangible" && diff.visible
            data = JSON.parse(diff.data)
            if data[0] == "Path"
              segments = data[1]["segments"]
              p segments
              for point in 1..(segments.length - 1)
                source = [segments[point-1][0][0].to_f, 777 - segments[point-1][0][1].to_f]
                dest = [segments[point][0][0].to_f, 777 - segments[point][0][1].to_f]
                bezier1 = [source[0] + segments[point-1][2][0].to_f, source[1] - segments[point-1][2][1].to_f]
                bezier2 = [dest[0] + segments[point][1][0].to_f, dest[1] - segments[point][1][1].to_f]
                curve source, dest, :bounds => [bezier1, bezier2]
              end
              red = data[1]["strokeColor"][0].to_i.to_s(16).rjust(2, '0').upcase
              green = data[1]["strokeColor"][1].to_i.to_s(16).rjust(2, '0').upcase
              blue = data[1]["strokeColor"][2].to_i.to_s(16).rjust(2, '0').upcase

              stroke_color "#{red}#{green}#{blue}"
              line_width 3
              stroke
            elsif data[0] == "PointText"
              puts "this is point text"
              puts data
              draw_text data[1]["content"], :at => [data[1]["matrix"][4].to_f, 777 - data[1]["matrix"][5].to_f], :size => 25
            end
          end
        end
      end
    end

    export.document.attach(io: File.open("export.pdf"), filename: "#{notebook.name}.pdf")

    File.delete("export.pdf")

    export.ready = true
    export.save
  end
end
