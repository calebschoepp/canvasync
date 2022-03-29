require 'test_helper'

class LayerChannelTest < ActionCable::Channel::TestCase
  test 'subscribes and stream for a match' do
    # Simulates the subscription to the channel
    subscribe layer_id: '1'

    # We can check that subscription was successfully created.
    assert subscription.confirmed?

    # We can check that channel subscribed the connection to correct stream
    assert_has_stream 'layer_channel_1'
  end

  test 'no subscription if layer identifier not present' do
    subscribe

    assert subscription.rejected?
  end

  test 'todo rename me' do
    subscribe layer_id: Layer.first.id

    expected_msg = { 'diff_type' => 'fetch-existing',
                     'data' =>
                      [{ 'diff_type' => 'tangible',
                         'seq' => 0,
                         'data' =>
                          '["Path",{"applyMatrix":true,"segments":[[[250,282],[0,0],[48.14208,-48.14208]],[[388,306],[-44.79859,-10.33814],[53.0259,12.23675]],[[527,251],[-34.26694,37.69363],[0,0]]],"strokeColor":[0,0,0],"strokeWidth":3}]',
                         'visible' => true },
                       { 'diff_type' => 'tangible',
                         'seq' => 2,
                         'data' =>
                          '["PointText",{"applyMatrix":false,"matrix":[1,0,0,1,549,594],"content":"some text","strokeColor":[0,0,0],"fontSize":25,"leading":30}]',
                         'visible' => true }],
                     'next_seq' => 5 }

    assert_broadcast_on("layer_channel_#{Layer.first.id}", expected_msg) do
      subscription.receive({ 'diff_type' => 'fetch-existing', 'seq' => 0 })
    end

  end
end
