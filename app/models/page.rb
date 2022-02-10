class Page < ApplicationRecord
  # TODO: Handle delete cascading
  has_many :layers
  belongs_to :notebook
  # TODO: Validations
end
