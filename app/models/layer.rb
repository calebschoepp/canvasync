class Layer < ApplicationRecord
  # TODO: Handle delete cascading
  has_many :diffs
  belongs_to :page
  belongs_to :writer, class_name: 'UserNotebook'
  # TODO: Validations
end
