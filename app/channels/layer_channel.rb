class LayerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "layer_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
