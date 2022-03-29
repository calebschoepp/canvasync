require 'test_helper'

module ApplicationCable
  class ConnectionTest < ActionCable::Connection::TestCase
    test 'connection is rejected without cookie set' do
      assert_reject_connection { connect }
    end
  end
end
