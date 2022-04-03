class UserNotebook < ApplicationRecord
  # Mandated by FR-4: Display.Notebooks through FR-13: Export.Notebook

  belongs_to :user
  belongs_to :notebook
  has_many :layers, foreign_key: :writer_id, dependent: :destroy
end
