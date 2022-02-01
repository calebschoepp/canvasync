class Notebook < ApplicationRecord
  # TODO: Handle delete cascading
  # TODO: Include PDF uploads
  # TODO: Validate that user_id notebook_id combo is unique?
  has_many :user_notebooks
  has_many :users, through: :user_notebooks
  validates :name, presence: true, length: {maximum: 100}

  def is_owner?(user)
    user_notebook = self.user_notebooks.find_by(user_id: user.id)
    unless user_notebook
      return false
    end
    user_notebook.is_owner
  end

  def is_participant?(user)
    user_notebook = self.user_notebooks.find_by(user_id: user.id)
    unless user_notebook
      return false
    end
    not user_notebook.is_owner
  end
end
