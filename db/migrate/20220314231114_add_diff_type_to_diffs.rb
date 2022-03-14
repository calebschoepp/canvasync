class AddDiffTypeToDiffs < ActiveRecord::Migration[7.1]
  def change
    add_column :diffs, :diff_type, :string, null: false
  end
end
