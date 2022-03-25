require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'insufficient_chars' do
    assert_not(User.new(password: '').password_is_complex)
  end

  test 'insufficient_chars_lower' do
    assert_not(User.new(password: 'p').password_is_complex)
  end

  test 'insufficient_chars_upper' do
    assert_not(User.new(password: 'P').password_is_complex)
  end

  test 'insufficient_chars_number' do
    assert_not(User.new(password: '1').password_is_complex)
  end

  test 'insufficient_chars_mixedcase' do
    assert_not(User.new(password: 'Pa').password_is_complex)
  end

  test 'insufficient_chars_lower_number' do
    assert_not(User.new(password: 'p1').password_is_complex)
  end

  test 'insufficient_chars_upper_number' do
    assert_not(User.new(password: 'P1').password_is_complex)
  end

  test 'insufficient_chars_all_types' do
    assert_not(User.new(password: 'Pa1').password_is_complex)
  end

  test 'sufficient_chars' do
    assert_not(User.new(password: '--------').password_is_complex)
  end

  test 'sufficient_chars_lower' do
    assert_not(User.new(password: 'password').password_is_complex)
  end

  test 'sufficient_chars_upper' do
    assert_not(User.new(password: 'PASSWORD').password_is_complex)
  end

  test 'sufficient_chars_number' do
    assert_not(User.new(password: '12345678').password_is_complex)
  end

  test 'sufficient_chars_mixedcase' do
    assert_not(User.new(password: 'PaSsWoRd').password_is_complex)
  end

  test 'sufficient_chars_lower_number' do
    assert_not(User.new(password: 'password123').password_is_complex)
  end

  test 'sufficient_chars_upper_number' do
    assert_not(User.new(password: 'PASSWORD123').password_is_complex)
  end

  test 'sufficient_chars_all_types' do
    assert(User.new(password: 'Password123').password_is_complex)
  end
end
