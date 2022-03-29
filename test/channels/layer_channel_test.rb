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

  test 'fetch-existing diff as owner' do
    layer = layers(:one)
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

    subscribe layer_id: layer.id
    assert_broadcast_on("layer_channel_#{layer.id}", expected_msg) do
      subscription.receive({ 'diff_type' => 'fetch-existing' })
    end
  end

  test 'tangible diff as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'tangible',
             'seq' => 5,
             'data' => '["Path",{"applyMatrix":true,"segments":[[[405,158],[0,0],[5.05073,-10.10146]],[[435,135],[-9.31515,5.39298],[71.53958,-41.41765]],[[649,162],[-72.17468,-3.43689],[48.97915,2.33234]],[[795,142],[-48.0427,8.00712],[0,0]]],"strokeColor":[0.22745,0.52549,1],"strokeWidth":3}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'remove diff as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { 'removed_diffs' => [0] } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_not(Diff.where(layer: layer.id, seq: 0).pluck(:visible).first)
  end

  test 'translate diff as owner' do
    layer = layers(:one)
    updated_diff = '["Path",{"applyMatrix":true,"segments":[[[260,292],[0,0],[48.14208,-48.14208]],[[388,306],[-44.79859,-10.33814],[53.0259,12.23675]],[[527,251],[-34.26694,37.69363],[0,0]]],"strokeColor":[0,0,0],"strokeWidth":3}]'
    diff = { 'diff_type' => 'translate',
             'seq' => 5,
             'data' => { 'translated_diffs' => [
               {
                 'seq' => 0,
                 'data' => updated_diff
               }
             ], 'delta_x' => 10, 'delta_y' => 10 } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_equal(Diff.where(layer: layer.id, seq: 0).pluck(:data).first, updated_diff)
  end

  test 'tangible pen diff as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'tangible',
             'seq' => 5,
             'data' => '["Path",{"applyMatrix":true,"segments":[[[405,158],[0,0],[5.05073,-10.10146]],[[435,135],[-9.31515,5.39298],[71.53958,-41.41765]],[[649,162],[-72.17468,-3.43689],[48.97915,2.33234]],[[795,142],[-48.0427,8.00712],[0,0]]],"strokeColor":[0.22745,0.52549,1],"strokeWidth":3}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'tangible text diff as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'tangible',
             'seq' => 5,
             'data' => '["PointText",{"applyMatrix":false,"matrix":[1,0,0,1,593,500],"content":"more text","fillColor":[0.98431,0.33725,0.02745],"strokeColor":[0.98431,0.33725,0.02745],"fontSize":25,"leading":30}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'invalid seq number (already existing seq) as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'tangible',
             'seq' => 2,
             'data' => '["Path",{"applyMatrix":true,"segments":[[[405,158],[0,0],[5.05073,-10.10146]],[[435,135],[-9.31515,5.39298],[71.53958,-41.41765]],[[649,162],[-72.17468,-3.43689],[48.97915,2.33234]],[[795,142],[-48.0427,8.00712],[0,0]]],"strokeColor":[0.22745,0.52549,1],"strokeWidth":3}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_no_difference('Diff.count') do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'empty removed_diffs array as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { removed_diffs: [] } }

    visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
    new_visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    assert_equal(visible_diffs, new_visible_diffs)
  end

  test 'array of valid remove_diffs (already existing seq) as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { 'removed_diffs' => [0, 2] } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_not(Diff.where(layer: layer.id, seq: 0).pluck(:visible).first)
    assert_not(Diff.where(layer: layer.id, seq: 2).pluck(:visible).first)
  end

  test "array of invalid remove_diffs (seq that don't exist) as owner" do
    layer = layers(:one)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { 'removed_diffs' => [10, 14] } }

    visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
    new_visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    assert_equal(visible_diffs, new_visible_diffs)
  end

  test 'empty translated_diffs array as owner' do
    layer = layers(:one)
    diff = { 'diff_type' => 'translate',
             'seq' => 5,
             'data' => { translated_diffs: [] } }

    diff_data = Diff.where(layer: layer.id, :visible => true).pluck(:data)
    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
    new_diff_data = Diff.where(layer: layer.id, :visible => true).pluck(:data)
    assert_equal(diff_data, new_diff_data)
  end

  test 'array of valid translated_diffs (already existing seq) as owner' do
    layer = layers(:one)
    updated_diff_zero = '["Path",{"applyMatrix":true,"segments":[[[260,292],[0,0],[48.14208,-48.14208]],[[388,306],[-44.79859,-10.33814],[53.0259,12.23675]],[[527,251],[-34.26694,37.69363],[0,0]]],"strokeColor":[0,0,0],"strokeWidth":3}]'
    updated_diff_two = '[\"PointText\",{\"applyMatrix\":false,\"matrix\":[1,0,0,1,559,604],\"content\":\"some text\",\"strokeColor\":[0,0,0],\"fontSize\":25,\"leading\":30}]'

    diff = { 'diff_type' => 'translate',
             'seq' => 5,
             'data' => { 'translated_diffs' => [{ 'seq' => 0, 'data' => updated_diff_zero }, { 'seq' => 2, 'data' => updated_diff_two }], delta_x: 10, delta_y: 10 } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_equal(Diff.where(layer: layer.id, seq: 0).pluck(:data).first, updated_diff_zero)
    assert_equal(Diff.where(layer: layer.id, seq: 2).pluck(:data).first, updated_diff_two)
  end

  test 'fetch-existing diff as participant' do
    layer = layers(:two)
    expected_msg = { 'diff_type' => 'fetch-existing',
                     'data' =>
                       [{ 'diff_type' => 'tangible',
                          'seq' => 0,
                          'data' =>
                            '["Path",{"applyMatrix":true,"segments":[[[230,222],[0,0],[48.14208,-48.14208]],[[388,306],[-44.79859,-10.33814],[53.0259,12.23675]],[[527,251],[-34.26694,37.69363],[0,0]]],"strokeColor":[0,0,0],"strokeWidth":3}]',
                          'visible' => true },
                        { 'diff_type' => 'tangible',
                          'seq' => 2,
                          'data' =>
                            '["PointText",{"applyMatrix":false,"matrix":[1,0,0,1,519,614],"content":"some text","strokeColor":[0,0,0],"fontSize":25,"leading":30}]',
                          'visible' => true }],
                     'next_seq' => 5 }

    subscribe layer_id: layer.id
    assert_broadcast_on("layer_channel_#{layer.id}", expected_msg) do
      subscription.receive({ 'diff_type' => 'fetch-existing' })
    end
  end

  test 'tangible diff as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'tangible',
             'seq' => 5,
             'data' => '["Path",{"applyMatrix":true,"segments":[[[405,158],[0,0],[5.05073,-10.10146]],[[435,135],[-9.31515,5.39298],[71.53958,-41.41765]],[[649,162],[-72.17468,-3.43689],[48.97915,2.33234]],[[795,142],[-48.0427,8.00712],[0,0]]],"strokeColor":[0.22745,0.52549,1],"strokeWidth":3}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'remove diff as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { 'removed_diffs' => [0] } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_not(Diff.where(layer: layer.id, seq: 0).pluck(:visible).first)
  end

  test 'translate diff as participant' do
    layer = layers(:two)
    updated_diff = '["Path",{"applyMatrix":true,"segments":[[[260,292],[0,0],[48.14208,-48.14208]],[[388,306],[-44.79859,-10.33814],[53.0259,12.23675]],[[527,251],[-34.26694,37.69363],[0,0]]],"strokeColor":[0,0,0],"strokeWidth":3}]'
    diff = { 'diff_type' => 'translate',
             'seq' => 5,
             'data' => { 'translated_diffs' => [
               {
                 'seq' => 0,
                 'data' => updated_diff
               }
             ], 'delta_x' => 10, 'delta_y' => 10 } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_equal(Diff.where(layer: layer.id, seq: 0).pluck(:data).first, updated_diff)
  end

  test 'tangible pen diff as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'tangible',
             'seq' => 5,
             'data' => '["Path",{"applyMatrix":true,"segments":[[[405,158],[0,0],[5.05073,-10.10146]],[[435,135],[-9.31515,5.39298],[71.53958,-41.41765]],[[649,162],[-72.17468,-3.43689],[48.97915,2.33234]],[[795,142],[-48.0427,8.00712],[0,0]]],"strokeColor":[0.22745,0.52549,1],"strokeWidth":3}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'tangible text diff as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'tangible',
             'seq' => 5,
             'data' => '["PointText",{"applyMatrix":false,"matrix":[1,0,0,1,593,500],"content":"more text","fillColor":[0.98431,0.33725,0.02745],"strokeColor":[0.98431,0.33725,0.02745],"fontSize":25,"leading":30}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'invalid seq number (already existing seq) as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'tangible',
             'seq' => 2,
             'data' => '["Path",{"applyMatrix":true,"segments":[[[405,158],[0,0],[5.05073,-10.10146]],[[435,135],[-9.31515,5.39298],[71.53958,-41.41765]],[[649,162],[-72.17468,-3.43689],[48.97915,2.33234]],[[795,142],[-48.0427,8.00712],[0,0]]],"strokeColor":[0.22745,0.52549,1],"strokeWidth":3}]',
             'visible' => true }

    subscribe layer_id: layer.id
    assert_no_difference('Diff.count') do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
  end

  test 'empty removed_diffs array as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { removed_diffs: [] } }

    visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
    new_visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    assert_equal(visible_diffs, new_visible_diffs)
  end

  test 'array of valid remove_diffs (already existing seq) as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { 'removed_diffs' => [0, 2] } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_not(Diff.where(layer: layer.id, seq: 0).pluck(:visible).first)
    assert_not(Diff.where(layer: layer.id, seq: 2).pluck(:visible).first)
  end

  test "array of invalid remove_diffs (seq that don't exist) as participant" do
    layer = layers(:two)
    diff = { 'diff_type' => 'remove',
             'seq' => 5,
             'data' => { 'removed_diffs' => [10, 14] } }

    visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
    new_visible_diffs = Diff.where(layer: layer.id, :visible => true).pluck(:seq)
    assert_equal(visible_diffs, new_visible_diffs)
  end

  test 'empty translated_diffs array as participant' do
    layer = layers(:two)
    diff = { 'diff_type' => 'translate',
             'seq' => 5,
             'data' => { translated_diffs: [] } }

    diff_data = Diff.where(layer: layer.id, :visible => true).pluck(:data)
    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end
    new_diff_data = Diff.where(layer: layer.id, :visible => true).pluck(:data)
    assert_equal(diff_data, new_diff_data)
  end

  test 'array of valid translated_diffs (already existing seq) as participant' do
    layer = layers(:two)
    updated_diff_zero = '["Path",{"applyMatrix":true,"segments":[[[260,292],[0,0],[48.14208,-48.14208]],[[388,306],[-44.79859,-10.33814],[53.0259,12.23675]],[[527,251],[-34.26694,37.69363],[0,0]]],"strokeColor":[0,0,0],"strokeWidth":3}]'
    updated_diff_two = '[\"PointText\",{\"applyMatrix\":false,\"matrix\":[1,0,0,1,559,604],\"content\":\"some text\",\"strokeColor\":[0,0,0],\"fontSize\":25,\"leading\":30}]'

    diff = { 'diff_type' => 'translate',
             'seq' => 5,
             'data' => { 'translated_diffs' => [{ 'seq' => 0, 'data' => updated_diff_zero }, { 'seq' => 2, 'data' => updated_diff_two }], delta_x: 10, delta_y: 10 } }

    subscribe layer_id: layer.id
    assert_difference('Diff.count', 1) do
      assert_broadcast_on("layer_channel_#{layer.id}", diff) do
        subscription.receive(diff)
      end
    end

    assert_equal(Diff.where(layer: layer.id, seq: 0).pluck(:data).first, updated_diff_zero)
    assert_equal(Diff.where(layer: layer.id, seq: 2).pluck(:data).first, updated_diff_two)
  end
end
