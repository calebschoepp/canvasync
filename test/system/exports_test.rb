require 'application_system_test_case'

class ExportsTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    sign_in users(:three)
    @export = exports(:one)
  end

  test 'export a notebook from start to finish and download' do
    visit notebooks_url
    find('button.ellipse').click
    click_on 'Export to PDF'
    click_on 'Export Notebook'
    assert_selector 'span', text: 'Exporting'
    sleep 1
    visit current_path
    assert_selector 'span', text: 'Ready'
    find('button.ellipse').click
    click_on 'Preview'
  end
end
