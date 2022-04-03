class Diff < ApplicationRecord
  # Mandated by FR-8: Open.Notebook and FR-10: OwnerEdit.Canvas through FR-13: Export.Notebook

  belongs_to :layer
  validates :seq, uniqueness: { scope: :layer }
end
