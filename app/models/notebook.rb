class Notebook < ApplicationRecord
  has_many :user_notebooks
  has_many :users, through: :user_notebooks
  validates :name, presence: true, length: {maximum: 100}
end
