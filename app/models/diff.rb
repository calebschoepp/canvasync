# TODO: Potentially use jsonb instead of json - this would require using Postgres locally
class Diff < ApplicationRecord
  belongs_to :layer
  validates :seq, uniqueness: { scope: :layer }
  # TODO: Validations
end
