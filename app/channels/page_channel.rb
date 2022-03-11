class PageChannel < ApplicationCable::Channel
  # TODO: store pages broadcasted by owner client in db
  def subscribed
    stream_from "page_channel_#{params[:notebook_id]}"
  end

  def receive(data)
    unless persist_page(data)
      # TODO: Handle scenario where save fails
      puts "\n\n\nFailed to save diff\n\n\n"
    end
    ActionCable.server.broadcast("page_channel_#{params[:notebook_id]}", data)
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def persist_page(data)

    @notebook = Notebook.find(params[:notebook_id].to_i)
    page_number = Page.page.where(notebook_id: params[:notebook_id]).max_by {|page| page.number}.number + 1
    page = Page.new(number: page_number, notebook: @notebook)
    # page.notebook_id = params[:notebook_id].to_i
    # page.number = Page.page.where(notebook_id: params[:notebook_id]).max_by {|page| page.number}.number + 1
    puts page.number
    page.save
  end
end
