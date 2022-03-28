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
      post notebooks_url, params: { notebook: { name: @notebook.name } }
    end

    assert_redirected_to notebook_url(Notebook.last)
    assert_nil(Notebook.last.background)
  end

  test 'should create notebook with PDF background' do
    assert_difference('Notebook.count') do
      post notebooks_url, params: { notebook: { name: @notebook.name, background: './test/examplePDF.pdf' } }
    end

    assert_redirected_to notebook_url(Notebook.last)
    assert_not_nil(Notebook.last.background)
  end

  test 'should create notebook with PNG background' do
    assert_difference('Notebook.count') do
      post notebooks_url, params: { notebook: { name: @notebook.name, background: './test/examplePNG.png' } }
    end

    assert_redirected_to notebook_url(Notebook.last)
    assert_not_nil(Notebook.last.background)
  end

  test 'should create notebook with JPG background' do
    assert_difference('Notebook.count') do
      post notebooks_url, params: { notebook: { name: @notebook.name, background: './test/exampleJPG.jpg' } }
    end

    assert_redirected_to notebook_url(Notebook.last)
    assert_not_nil(Notebook.last.background)
  end

  test 'should create notebook with PPT background' do
    assert_difference('Notebook.count') do
      post notebooks_url, params: { notebook: { name: @notebook.name, background: './test/examplePPT.pptx' } }
    end

    assert_redirected_to notebook_url(Notebook.last)
    assert_not_nil(Notebook.last.background)
  end

  test 'should show notebook' do
    get notebook_url(@notebook)
    assert_response :success
  end

  test 'should get edit' do
    get edit_notebook_url(@notebook)
    assert_response :success
  end

  test 'should update notebook' do
    patch notebook_url(@notebook), params: { notebook: { name: @notebook.name } }
    assert_redirected_to notebook_url(@notebook)
  end

  test 'should destroy notebook' do
    assert_difference('Notebook.count', -1) do
      delete notebook_url(@notebook)
    end

    assert_redirected_to notebooks_url
  end
end
