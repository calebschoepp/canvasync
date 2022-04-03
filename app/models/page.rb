class Page < ApplicationRecord
  # Mandated by FR-8: Open.Notebook through FR-13: Export.Notebook

  has_many :layers, dependent: :destroy
  belongs_to :notebook
end
