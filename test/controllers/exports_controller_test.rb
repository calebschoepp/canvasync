require 'test_helper'

class ExportsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:one)
    @export = exports(:one)
  end

  test 'should get index' do
    get notebook_exports_url notebooks(:one)
    assert_response :success
  end

  test 'should create export if participant or owner' do
    assert_difference('Export.count') do
      post notebook_exports_url notebooks(:one), params: { export: { user_id: users(:one).id, notebook_id: @export.notebook_id, ready: @export.ready, failed: @export.failed } }
    end
  end

  test 'should not create export if not participant or owner' do
    assert_no_difference('Export.count') do
      post notebook_exports_url notebooks(:one), params: { export: { user_id: users(:four).id, notebook_id: @export.notebook_id, ready: @export.ready, failed: @export.failed } }
    end
  end

  test 'should destroy export' do
    assert_difference('Export.count', -1) do
      delete export_url(@export)
    end

    assert_redirected_to notebook_exports_url notebooks(:one)
  end
end
