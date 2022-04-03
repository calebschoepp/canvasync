class Layer < ApplicationRecord
  # Mandated by FR-8: Open.Notebook through FR-13: Export.Notebook
  #
  has_many :diffs, dependent: :destroy
  belongs_to :page
  belongs_to :writer, class_name: 'UserNotebook', foreign_key: :writer_id

  def as_json(_options = nil)
    layer = super()
    layer['writer'] = writer.as_json
    layer
  end
end
