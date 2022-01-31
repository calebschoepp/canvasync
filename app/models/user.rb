class User < ApplicationRecord
  rolify
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :trackable
  # TODO: Handle delete cascading
  has_many :user_notebooks
  has_many :notebooks, through: :user_notebooks
end
