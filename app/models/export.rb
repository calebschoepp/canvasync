class Export < ApplicationRecord
  # Mandated by FR-13: Export.Notebook

  belongs_to :notebook
  belongs_to :user
  has_one_attached :document, dependent: :purge_later

  def current
    # Hella inefficient but YOLO
    notebook.pages
            .flat_map(&:layers)
            .filter { |layer| layer.writer.user.id == user.id || layer.writer.user.id == notebook.owner.id }
            .flat_map(&:diffs)
            .none? { |diff| diff.updated_at > updated_at }
  end
end
