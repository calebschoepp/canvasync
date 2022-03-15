# TODO: Improve logging

class LayerChannel < ApplicationCable::Channel
  TANGIBLE_DIFF = 'tangible'.freeze
  REMOVE_DIFF = 'remove'.freeze
  TRANSLATE_DIFF = 'translate'.freeze

  def subscribed
    stream_from "layer_channel_#{params[:layer_id]}"
    # Send existing diffs for the layer
    ActionCable.server.broadcast("layer_channel_#{params[:layer_id]}",
                                 Diff.where(layer_id: params[:layer_id]).order(:seq).pluck(:diff_type, :seq, :data, :visible))
  end

  def receive(data)
    # Always persist incoming diff
    persist_diff(data)

    # Apply possible side effects of incoming diff
    diff_type = data['diff_type']
    diff_data = data['data']

    case diff_type
    when REMOVE_DIFF
      # Mark removed diffs as invisible
      Diff.where(seq: diff_data).map { |diff| diff.update_attribute(:visible, false) }
    when TRANSLATE_DIFF
      # Update data of translated diffs
      diff_data.each do |translated_diff|
        diff = Diff.where(seq: translated_diff['seq'], layer_id: params[:layer_id]).first
        diff&.update_attribute(:data, translated_diff['data'])
      end
    end
  rescue StandardError => e
    # TODO: Handle scenario where save fails
    puts "Failed to save and process incoming diff!\n#{e.inspect}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  private

  def persist_diff(diff)
    diff_type = diff['diff_type']
    diff_seq = diff['seq']
    diff_visible = diff['visible']
    diff_data = diff['data']
    return false if diff_type.nil? || diff_seq.nil? || diff_data.nil?

    diff = Diff.new
    diff.diff_type = diff_type
    diff.seq = diff_seq
    diff.data = diff_data
    diff.visible = diff_visible unless diff_visible.nil?
    diff.layer_id = params[:layer_id]
    diff.save!
  end
end
