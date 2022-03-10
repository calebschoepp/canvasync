class UserNotebook < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
  has_many :layers, foreign_key: :writer_id, dependent: :destroy
  # TODO: Validate that there is only one owner per notebook
end
