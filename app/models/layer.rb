class Layer < ApplicationRecord
  # TODO: Handle delete cascading
  has_many :diffs, dependent: :destroy
  belongs_to :page
  belongs_to :writer, class_name: 'UserNotebook', foreign_key: :writer_id
  # TODO: Validations

  def as_json(_options = nil)
    layer = super()
    layer['writer'] = writer.as_json
    layer
  end
end
