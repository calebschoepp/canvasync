class Page < ApplicationRecord
  has_many :layers
  belongs_to :notebook
end
