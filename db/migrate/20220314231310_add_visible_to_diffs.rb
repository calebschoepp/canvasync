class AddVisibleToDiffs < ActiveRecord::Migration[7.1]
  def change
    add_column :diffs, :visible, :boolean, null: false, default: true
  end
end
