require 'test_helper'

class NotebooksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:four)
    @notebook = notebooks(:one)
  end

  test 'should get index' do
    get notebooks_url
    assert_response :success
  end

  test 'should get new' do
    get new_notebook_url
    assert_response :success
  end

  test 'should create notebook with no background' do
    assert_difference('Notebook.count') do
      post notebooks_url, params: { notebook: { name: "new notebook" } }
    end

    assert_equal(Notebook.last.name, "new notebook")
    assert_not(Notebook.last.background.attached?)
  end

  test 'should create notebook with a background' do
    assert_difference('Notebook.count') do
      post notebooks_url, params: { notebook: { name: "new notebook", background: fixture_file_upload('./examplePDF.pdf') } }
    end

    assert_equal(Notebook.last.name, "new notebook")
    assert(Notebook.last.background.attached?)
  end

  test 'should show notebook' do
    get notebook_url(@notebook)
    assert_response :success
  end

  # test 'should get edit' do
  #   get edit_notebook_url(@notebook)
  #   assert_response :success
  # end

  # test 'should update notebook' do
  #   patch notebook_url(@notebook), params: { notebook: { name: @notebook.name } }
  #   assert_redirected_to notebook_url(@notebook)
  # end

  # test 'should destroy notebook' do
  #   assert_difference('Notebook.count', -1) do
  #     delete notebook_url(@notebook)
  #   end

  #   assert_redirected_to notebooks_url
  # end
end
