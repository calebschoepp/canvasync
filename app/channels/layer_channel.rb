class LayerChannel < ApplicationCable::Channel
  # TODO: store diffs broadcasted by owner client in db
  # TODO: receive diffs from participant and store them in db
  def subscribed
    stream_from "layer_channel_#{params[:layer_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
