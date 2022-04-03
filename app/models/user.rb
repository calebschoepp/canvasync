class User < ApplicationRecord
  # Mandated by all functional requirements

  MIN_LENGTH = 6

  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable

  has_many :user_notebooks, dependent: :destroy
  has_many :notebooks, through: :user_notebooks
  has_many :exports, dependent: :destroy

  validate :password_complexity

  def password_complexity
    errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit' if password.present? && !password_is_complex
  end

  def password_is_complex
    !password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)./).nil? && password.length >= MIN_LENGTH
  end
end
