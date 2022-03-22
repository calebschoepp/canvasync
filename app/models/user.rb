class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  # TODO: Handle delete cascading
  has_many :user_notebooks, dependent: :destroy
  has_many :notebooks, through: :user_notebooks
  has_many :exports, dependent: :destroy

  validate :password_complexity

  private

  def password_complexity
    errors.add :password, 'must include at least one lowercase letter, one uppercase letter, and one digit' if password.present? && !password.match(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)./)
  end
end
