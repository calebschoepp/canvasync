class CreateLayers < ActiveRecord::Migration[7.1]
  def change
    create_table :layers do |t|
      t.references :page, null: false, foreign_key: true
      t.references :writer, null: false, foreign_key: { to_table: :user_notebooks}

      t.timestamps
    end
  end
end
