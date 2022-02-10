class Layer < ApplicationRecord
  belongs_to :page
  belongs_to :writer, class_name: 'UserNotebook'
end
