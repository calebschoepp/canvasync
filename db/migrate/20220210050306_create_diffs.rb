class CreateDiffs < ActiveRecord::Migration[7.1]
  def change
    create_table :diffs do |t|
      t.references :layer, null: false, foreign_key: true
      t.integer :seq, null: false
      t.json :data, null: false, default: '{}'
      t.boolean :visible, null: false, default: true
      t.string :type, null: false
      t.timestamps
    end
  end
end
