class UserNotebook < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
  # TODO: Validate that there is only one owner per notebook
end
