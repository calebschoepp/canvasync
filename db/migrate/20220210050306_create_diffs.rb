class CreateDiffs < ActiveRecord::Migration[7.1]
  def change
    create_table :diffs do |t|
      t.references :layer, null: false, foreign_key: true
      t.integer :seq
      t.json :data, null: false, default: '{}'

      t.timestamps
    end
  end
end
