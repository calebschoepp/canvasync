class LayerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "layer_channel_#{params[:layer_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
