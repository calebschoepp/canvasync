class Notebook < ApplicationRecord
  ALLOWED_FILE_TYPES = ['application/pdf'].freeze
  FILE_SIZE_SETTINGS = { less_than: 30.megabytes, message: 'is not given between size' }.freeze

  # TODO: Validate that user_id notebook_id combo is unique?
  has_many :user_notebooks, dependent: :destroy
  has_many :users, through: :user_notebooks
  has_many :pages, dependent: :destroy
  has_many :exports, dependent: :destroy
  has_one_attached :background, dependent: :purge_later
  validates :name, presence: true, length: { maximum: 100 }
  validates :background, content_type: ALLOWED_FILE_TYPES, size: FILE_SIZE_SETTINGS

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

  def owner
    user_notebook = user_notebooks.find_by(is_owner: true)
    user_notebook.user
  end
end
