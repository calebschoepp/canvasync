class Layer < ApplicationRecord
  has_many :diffs
  belongs_to :page
  belongs_to :writer, class_name: 'UserNotebook'
end
