# TODO: Improve logging

class LayerChannel < ApplicationCable::Channel
  TANGIBLE_DIFF = 'tangible'.freeze
  REMOVE_DIFF = 'remove'.freeze
  TRANSLATE_DIFF = 'translate'.freeze
  FETCH_EXISTING_SIGNAL = 'fetch-existing'.freeze

  def subscribed
    stream_from "layer_channel_#{params[:layer_id]}"
    puts "Connection established with layer #{params[:layer_id]}"
    # Send existing diffs for the layer
    puts "Transmitting existing diffs for layer #{params[:layer_id]}"
    transmit(existing_diffs_for_layer)
  end

  def receive(data)
    diff_type = data['diff_type']

    # If channel requests existing data, transmit existing diffs back
    if diff_type.eql?(FETCH_EXISTING_SIGNAL)
      puts "Broadcasting existing diffs for layer #{params[:layer_id]}"
      ActionCable.server.broadcast("layer_channel_#{params[:layer_id]}", existing_diffs_for_layer)
      return
    end

    # Rebroadcast diff to all clients then persist it
    ActionCable.server.broadcast("layer_channel_#{params[:layer_id]}", data)
    persist_diff(data)

    # Apply possible side effects of incoming diff
    diff_data = data['data']
    case diff_type
    when REMOVE_DIFF
      # Mark removed diffs as invisible
      puts diff_data['removed_diffs']
      Diff.where(seq: diff_data['removed_diffs'], layer_id: params[:layer_id]).map { |diff| diff.update_attribute(:visible, false) }
    when TRANSLATE_DIFF
      # Update data of translated diffs
      diff_data['translated_diffs'].each do |translated_diff|
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

  def existing_diffs_for_layer
    existing_diffs = Diff.where(layer_id: params[:layer_id])
    visible_diffs = []
    next_seq = 0
    if existing_diffs.length.positive?
      # Only get the visible diffs
      existing_diffs.where(visible: true).order(:seq).pluck(:diff_type, :seq, :data, :visible).each do |diff|
        visible_diffs.push({ 'diff_type' => diff[0], 'seq' => diff[1], 'data' => diff[2], 'visible' => diff[3] })
      end
      # Get the value of the next expected diff seq
      next_seq = existing_diffs.maximum(:seq) + 1
    end
    {
      'diff_type' => FETCH_EXISTING_SIGNAL,
      'data' => visible_diffs.as_json,
      'next_seq' => next_seq
    }
  end
end
