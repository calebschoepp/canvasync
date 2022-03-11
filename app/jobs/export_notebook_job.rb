class ExportNotebookJob < ApplicationJob
  queue_as :default

  def perform(export_id)
    # TODO: Actually export notebook
    sleep(5) # TODO: Remove this sleep
    export = Export.find(export_id)
    notebook = export.notebook
    export.document = notebook.background.blob
    export.ready = true
    export.save
  end
end
