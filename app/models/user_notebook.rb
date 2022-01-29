class UserNotebook < ApplicationRecord
  belongs_to :user
  belongs_to :notebook
end
