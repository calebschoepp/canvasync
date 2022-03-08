class Notebook < ApplicationRecord
  # TODO: Handle delete cascading
  # TODO: Include PDF uploads
  # TODO: Validate that user_id notebook_id combo is unique?
  has_many :user_notebooks, dependent: :destroy
  has_many :users, through: :user_notebooks
  has_many :pages, dependent: :destroy
  validates :name, presence: true, length: { maximum: 100 }

  def owner?(user)
    user_notebook = user_notebooks.find_by(user_id: user.id)
    return false unless user_notebook

    user_notebook.is_owner
  end

  def participant?(user)
    user_notebook = user_notebooks.find_by(user_id: user.id)
    return false unless user_notebook

    !user_notebook.is_owner
  end
end
