class Export < ApplicationRecord
  belongs_to :notebook
  belongs_to :user
  has_one_attached :document, dependent: :purge_later

  def  current
    # Hella inefficient but YOLO
    !notebook.pages
            .flat_map(&:layers)
            .filter { |layer| layer.writer.id == user.id || layer.writer.id == notebook.owner.id }
            .flat_map(&:diffs)
            .any? { |diff| diff.updated_at > updated_at }
  end
end
