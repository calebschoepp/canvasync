class AddVisibleToDiffs < ActiveRecord::Migration[7.1]
  def change
    add_column :diffs, :visible, :boolean
  end
end
