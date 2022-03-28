require 'application_system_test_case'

class RegistrationTest < ApplicationSystemTestCase
  test 'email is not unique' do
    visit new_user_registration_url
    fill_in 'user[email]', with: users(:one).email
    fill_in 'user[password]', with: 'Password1'
    fill_in 'user[password_confirmation]', with: 'Password1'
    click_on 'commit'
    assert_text 'Email has already been taken'
  end

  test 'email is unique' do
    visit new_user_registration_url
    fill_in 'user[email]', with: 'atotallynewemail@cool.com'
    fill_in 'user[password]', with: 'Password1'
    fill_in 'user[password_confirmation]', with: 'Password1'
    click_on 'commit'
    assert_selector 'h1', text: 'Your Notebooks'
  end

  test 'password confirmation matches' do
    visit new_user_registration_url
    fill_in 'user[email]', with: 'atotallynewemail@cool.com'
    fill_in 'user[password]', with: 'MatchingPass1'
    fill_in 'user[password_confirmation]', with: 'MatchingPass1'
    click_on 'commit'
    assert_selector 'h1', text: 'Your Notebooks'
  end

  test 'email is unique but password confirmation does not match' do
    visit new_user_registration_url
    fill_in 'user[email]', with: 'atotallynewemail@cool.com'
    fill_in 'user[password]', with: 'Password1'
    fill_in 'user[password_confirmation]', with: '3Password'
    click_on 'commit'
    assert_text 'Password confirmation doesn\'t match Password'
  end
end
