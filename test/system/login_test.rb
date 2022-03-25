require 'application_system_test_case'

class LoginTest < ApplicationSystemTestCase
  test 'email matches and password matches' do
    visit new_user_session_url
    fill_in 'user[email]', with: users(:one).email
    fill_in 'user[password]', with: '123greetings'
    click_on 'commit'
    assert_selector 'h1', text: 'Your Notebooks'
  end

  test 'email does not match and password matches' do
    visit new_user_session_url
    fill_in 'user[email]', with: 'wrong@email.com'
    fill_in 'user[password]', with: '123greetings'
    click_on 'commit'
    assert_text 'Invalid Email or password.'
  end

  test 'email matches and password does not match' do
    visit new_user_session_url
    fill_in 'user[email]', with: users(:one).email
    fill_in 'user[password]', with: 'sadf'
    click_on 'commit'
    assert_text 'Invalid Email or password.'
  end

  test 'email does not match and password does not match' do
    visit new_user_session_url
    fill_in 'user[email]', with: 'wrong@email.com'
    fill_in 'user[password]', with: 'adsf'
    click_on 'commit'
    assert_text 'Invalid Email or password.'
  end
end
