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

  test 'added notebook does not exist' do
    sign_in users(:four)
    visit notebooks_url
    find(id: 'add-notebook-input').set 'this-does-not-exist'
    click_on 'Join a Notebook'
    assert_current_path notebooks_url
  end

  test 'added notebook exists but is already owned' do
    sign_in users(:four)
    visit notebooks_url
    find(id: 'add-notebook-input').set notebooks(:two).id
    click_on 'Join a Notebook'
    assert_text 'You are already an owner of this notebook'
    assert_current_path notebooks_url
  end

  test 'added notebook exists but is already added' do
    sign_in users(:four)
    visit notebooks_url
    find(id: 'add-notebook-input').set notebooks(:one).id
    click_on 'Join a Notebook'
    assert_text 'You are already a participant of this notebook'
    assert_current_path notebooks_url
  end

  test 'added notebook exists and is not already owned or added' do
    sign_in users(:four)
    visit notebooks_url
    find(id: 'add-notebook-input').set notebooks(:three).id
    click_on 'Join a Notebook'
    assert_current_path preview_notebook_url(:id => notebooks(:three).id)
    assert_text 'Notebook3'
  end

  test 'user does not confirm joining of notebook that is valid to join' do
    sign_in users(:four)
    visit notebooks_url
    find(id: 'add-notebook-input').set notebooks(:three).id
    click_on 'Join a Notebook'
    assert_current_path preview_notebook_url(:id => notebooks(:three).id)
    click_on 'No'
    assert_current_path notebooks_url
    assert_no_text 'Notebook3'
  end

  test 'user confirms joining of notebook that is valid to join' do
    sign_in users(:four)
    visit notebooks_url
    find(id: 'add-notebook-input').set notebooks(:three).id
    click_on 'Join a Notebook'
    assert_current_path preview_notebook_url(:id => notebooks(:three).id)
    click_on 'Yes'
    assert_current_path notebook_url(:id => notebooks(:three).id)
    assert_text 'Notebook3'
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
