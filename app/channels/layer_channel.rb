class LayerChannel < ApplicationCable::Channel
  # TODO: store diffs broadcasted by owner client in db
  # TODO: receive diffs from participant and store them in db
  def subscribed
    stream_from "layer_channel_#{params[:layer_id]}"

    # Send existing diffs for the layer
    ActionCable.server.broadcast("layer_channel_#{params[:layer_id]}",
                                 Diff.where(layer_id: params[:layer_id]).order(:seq).pluck(:seq, :visible, :data))
  end

  def receive(data)
    unless persist_diff(data)
      # TODO: Handle scenario where save fails
      puts 'Failed to save diff!'
    end
    puts 'Successfully saved diff!'
    # TODO: refactor so 'Eraser' is not hardcoded
    if data['type'].eql?('Eraser')
      Diff.where(seq: data['data']).map(&diff.update_attribute(visible: false))
      # TODO: rebroadcast if owner layer
      ActionCable.server.broadcast("layer_channel_#{params[:layer_id]}", data)
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def persist_diff(diff)
    puts diff

    diff_type = diff['type']
    diff_seq = diff['seq']
    diff_data = diff['data']
    return false if diff_type.nil? || diff_seq.nil? || diff_data.nil?

    diff = Diff.new
    diff.type = diff_type
    diff.seq = diff_seq
    diff.data = diff_data
    diff.visible = diff_type.eql?('Pen') || diff_type.eql?('Text')
    diff.layer_id = params[:layer_id]
    diff.save!
  rescue StandardError => e
    # TODO: Improve logging
    puts "Failed to save diff!\n#{e.inspect}"
    false
  end
end
