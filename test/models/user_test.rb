require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
  test 'insufficient number of chars' do
    assert_not(User.new(password: '').password_is_complex)
  end

  test 'insufficient number of characters lowercase' do
    assert_not(User.new(password: 'p').password_is_complex)
  end

  test 'insufficient number of characters uppercase' do
    assert_not(User.new(password: 'P').password_is_complex)
  end

  test 'insufficient number of characters numbers' do
    assert_not(User.new(password: '1').password_is_complex)
  end

  test 'insufficient number of characters mixedcase' do
    assert_not(User.new(password: 'Pa').password_is_complex)
  end

  test 'insufficient number of characters lowercase and number' do
    assert_not(User.new(password: 'p1').password_is_complex)
  end

  test 'insufficient number of characters uppercase and number' do
    assert_not(User.new(password: 'P1').password_is_complex)
  end

  test 'insufficient number of characters all types of characters' do
    assert_not(User.new(password: 'Pa1').password_is_complex)
  end

  test 'sufficient number of characters' do
    assert_not(User.new(password: '--------').password_is_complex)
  end

  test 'sufficient number of characters lowercase' do
    assert_not(User.new(password: 'password').password_is_complex)
  end

  test 'sufficient number of characters uppercase' do
    assert_not(User.new(password: 'PASSWORD').password_is_complex)
  end

  test 'sufficient number of characters numbers' do
    assert_not(User.new(password: '12345678').password_is_complex)
  end

  test 'sufficient number of characters mixedcase' do
    assert_not(User.new(password: 'PaSsWoRd').password_is_complex)
  end

  test 'sufficient number of characters lowercase and number' do
    assert_not(User.new(password: 'password123').password_is_complex)
  end

  test 'sufficient number of characters uppercase and number' do
    assert_not(User.new(password: 'PASSWORD123').password_is_complex)
  end

  test 'sufficient number of characters all types of characters' do
    assert(User.new(password: 'Password123').password_is_complex)
  end
end
