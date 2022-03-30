require 'test_helper'

class PageChannelTest < ActionCable::Channel::TestCase
  test 'subscribes and stream for a page channel match' do
    # Simulates the subscription to the channel
    subscribe notebook_id: '1'

    # We can check that subscription was successfully created.
    assert subscription.confirmed?

    # We can check that channel subscribed the connection to correct stream
    assert_has_stream 'page_channel_1'
  end

  test 'no subscription for page channel if notebook identifier not present' do
    subscribe

    assert subscription.rejected?
  end

  test 'create new page as owner' do
    notebook = notebooks(:one)
    subscribe notebook_id: notebook.id
    assert_difference('Page.count', 1) do
      subscription.receive(nil)
      new_layers = Page.last.layers.as_json
      assert_broadcasts "page_channel_#{notebook.id}", 1
      assert_broadcast_on "page_channel_#{notebook.id}", new_layers
    end
  end

  test 'create new page as owner creates as many new layers as user_notebooks' do
    notebook = notebooks(:one)
    num_user_notebook = notebook.user_notebooks.count
    subscribe notebook_id: notebook.id
    assert_difference('Page.count', 1) do
      assert_difference('Layer.count', num_user_notebook) do
        subscription.receive(nil)
        new_layers = Page.last.layers.as_json
        assert_broadcasts "page_channel_#{notebook.id}", 1
        assert_broadcast_on "page_channel_#{notebook.id}", new_layers
      end
    end
  end

  test 'assert new page number matches next incremental page' do
    notebook = notebooks(:one)
    num_pages = notebook.pages.count
    subscribe notebook_id: notebook.id
    assert_difference('Page.count', 1) do
      subscription.receive(nil)
      new_layers = Page.last.layers.as_json
      assert_broadcasts "page_channel_#{notebook.id}", 1
      assert_broadcast_on "page_channel_#{notebook.id}", new_layers
    end
    assert_equal(notebook.pages.count, num_pages + 1)
  end

  test 'assert new layers belong to connected user_notebooks' do
    notebook = notebooks(:one)
    user_notebooks = notebook.user_notebooks.pluck(:user_id)
    subscribe notebook_id: notebook.id
    assert_difference('Page.count', 1) do
      subscription.receive(nil)
      new_layers = Page.last.layers.as_json
      assert_broadcasts "page_channel_#{notebook.id}", 1
      assert_broadcast_on "page_channel_#{notebook.id}", new_layers
    end
    assert_equal(Page.last.layers.map { |layer| layer.writer.user_id}, user_notebooks)
  end
end