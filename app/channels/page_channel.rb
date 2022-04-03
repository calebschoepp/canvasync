class PageChannel < ApplicationCable::Channel
  # Mandated by FR-11: New.Canvas

  def subscribed
    reject unless params[:notebook_id]
    stream_from "page_channel_#{params[:notebook_id]}"
  end

  def receive(_data)
    unless (page = persist_page)
      puts "Failed to save page!"
    end
    ActionCable.server.broadcast("page_channel_#{params[:notebook_id]}", page.layers.as_json)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def persist_page
    @notebook = Notebook.find(params[:notebook_id].to_i)
    page_number = Page.where(notebook_id: params[:notebook_id]).max_by(&:number).number + 1
    page = Page.new(number: page_number, notebook: @notebook)
    user_notebooks = UserNotebook.where(notebook: @notebook)
    user_notebooks.each do |user_notebook|
      page.layers << Layer.new(page: page, writer: user_notebook)
    end
    @notebook.pages << page
    page
  end
end
