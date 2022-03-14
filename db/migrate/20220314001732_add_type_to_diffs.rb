class AddTypeToDiffs < ActiveRecord::Migration[7.1]
  def change
    add_column(:diffs, :type, :string, null: false)
  end
end
