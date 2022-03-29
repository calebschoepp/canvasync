class AddUniqueIndexToDiffs < ActiveRecord::Migration[7.1]
  def change
    add_index :diffs, %i[seq layer_id], unique: true
  end
end
