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
end
