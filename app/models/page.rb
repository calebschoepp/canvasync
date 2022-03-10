class Page < ApplicationRecord
  # TODO: Handle delete cascading
  has_many :layers, dependent: :destroy
  belongs_to :notebook
  # TODO: Validations
end
