class LayerChannel < ApplicationCable::Channel
  # TODO: store diffs broadcasted by owner client in db
  # TODO: receive diffs from participant and store them in db
  def subscribed
    stream_from "layer_channel_#{params[:layer_id]}"
  end

  def receive(data)
    unless persist_diff(data)
      # TODO: Handle scenario where save fails
      puts "\n\n\nFailed to save diff\n\n\n"
    end
    rebroadcast = data['rebroadcast']
    ActionCable.server.broadcast("layer_channel_#{params[:layer_id]}", data) if rebroadcast
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def persist_diff(data)
    client_diff = data['diff']
    return false if client_diff.nil?

    seq = data['seq']
    return false if seq.nil?

    diff = Diff.new
    diff.data = client_diff
    diff.seq = seq
    diff.layer_id = params[:layer_id]
    diff.save
  end
end
