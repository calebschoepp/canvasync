require 'application_system_test_case'

# TODO why do some of these occasionally fail?
class SearchTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:four)
  end

  test 'search bar has no content' do
    visit notebooks_url

    assert_selector 'input', id: 'notebook-search-bar'
    assert_no_selector 'div', id: 'results'
  end

  test 'search bar has content and no matches' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'No matching notebooks'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is partial match case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Note'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'a', text: 'Notebook1'
      assert_selector 'a', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is exact match case sensitive' do
    visit notebooks_url

    # TODO why is this failing?
    find(id: 'notebook-search-bar').set 'Notebook2'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is partial match non case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'NOTE'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is exact match non case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'NOTEBook1'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_no_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and user is owner of matching notebook' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook2'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and user is not owner of matching notebook' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook1'
    Selenium::WebDriver::Wait.new(:timeout => 1)
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_no_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'clicking on result redirects to the notebook' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook1'
    assert_selector 'div', id: 'results' do
      click_on id: 'search-result', text: 'Notebook1'
    end

    # TODO weird error here?
    assert_redirected_to "notebooks/#{notebooks(:one).id}"
  end
end
