class PageChannel < ApplicationCable::Channel
  # TODO: store pages broadcasted by owner client in db
  def subscribed
    stream_from "page_channel_#{params[:notebook_id]}"
  end

  def receive(_data)
    unless (page = persist_page)
      # TODO: Handle scenario where save fails
      puts "\n\n\nFailed to save page\n\n\n"
    end
    ActionCable.server.broadcast("page_channel_#{params[:notebook_id]}", page.layers)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def persist_page
    @notebook = Notebook.find(params[:notebook_id].to_i)
    page_number = Page.page.where(notebook_id: params[:notebook_id]).max_by(&:number).number + 1
    page = Page.new(number: page_number, notebook: @notebook)
    user_notebooks = UserNotebook.where(notebook: @notebook)
    user_notebooks.each do |user_notebook|
      page.layers << Layer.new(page: page, writer_id: user_notebook.user_id)
    end
    @notebook.pages << page
    page
  end
end
