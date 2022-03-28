require 'application_system_test_case'

class NotebooksTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  test 'has neither joined nor created notebooks' do
    sign_in users(:one)
    visit notebooks_url
    assert_text 'You don\'t have any of your own notebooks yet. Create one to get started.'
    assert_text 'You haven\'t joined any notebooks yet. Enter a notebook code to join it and get started.'
  end

  test 'has created but not joined notebooks' do
    sign_in users(:two)
    visit notebooks_url
    assert_no_text 'You don\'t have any of your own notebooks yet. Create one to get started.'
    assert_text 'You haven\'t joined any notebooks yet. Enter a notebook code to join it and get started.'

    assert_selector 'div', id: 'owned-notebooks' do
      assert_selector 'a', text: 'Notebook1'
    end
  end

  test 'has joined but not created notebooks' do
    sign_in users(:three)
    visit notebooks_url
    assert_text 'You don\'t have any of your own notebooks yet. Create one to get started.'
    assert_no_text 'You haven\'t joined any notebooks yet. Enter a notebook code to join it and get started.'

    assert_selector 'div', id: 'joined-notebooks' do
      assert_selector 'a', text: 'Notebook1'
    end
  end

  test 'has both created and joined notebooks' do
    sign_in users(:four)
    visit notebooks_url
    assert_no_text 'You don\'t have any of your own notebooks yet. Create one to get started.'
    assert_no_text 'You haven\'t joined any notebooks yet. Enter a notebook code to join it and get started.'

    assert_selector 'div', id: 'owned-notebooks' do
      assert_selector 'a', text: 'Notebook2'
    end
    assert_selector 'div', id: 'joined-notebooks' do
      assert_selector 'a', text: 'Notebook1'
    end
  end

  # test 'should create notebook' do
  #   visit notebooks_url
  #   click_on 'New notebook'

  #   fill_in 'Name', with: @notebook.name
  #   click_on 'Create Notebook'

  #   assert_text 'Notebook was successfully created'
  #   click_on 'Back'
  # end

  # test 'should update Notebook' do
  #   visit notebook_url(@notebook)
  #   click_on 'Edit this notebook', match: :first

  #   fill_in 'Name', with: @notebook.name
  #   click_on 'Update Notebook'

  #   assert_text 'Notebook was successfully updated'
  #   click_on 'Back'
  # end

  # test 'should destroy Notebook' do
  #   visit notebook_url(@notebook)
  #   click_on 'Destroy this notebook', match: :first

  #   assert_text 'Notebook was successfully destroyed'
  # end
end
