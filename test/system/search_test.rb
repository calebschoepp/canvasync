require 'application_system_test_case'

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
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is partial match case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Note'
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'a', text: 'Notebook1'
      assert_selector 'a', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is exact match case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook2'
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is partial match non case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'NOTE'
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and is exact match non case sensitive' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'NOTEBook1'
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and user is owner of matching notebook' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook2'
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook2'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'search bar has content and user is not owner of matching notebook' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook1'
    sleep 0.5
    assert_selector 'div', id: 'results' do
      assert_selector 'a', id: 'search-result', text: 'Notebook1'
      assert_no_selector 'div', text: 'No results found!'
    end
  end

  test 'clicking on result redirects to the notebook' do
    visit notebooks_url

    find(id: 'notebook-search-bar').set 'Notebook1'
    assert_selector 'div', id: 'results' do
      click_on id: 'search-result', text: 'Notebook1'
    end

    # assert_redirected_to notebook_url(Notebook.last)
    expect(page.current_path).to eq notebook_url(Notebook.last)
  end
end
