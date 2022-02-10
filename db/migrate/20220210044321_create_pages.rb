class CreatePages < ActiveRecord::Migration[7.1]
  def change
    create_table :pages do |t|
      t.integer :number
      t.references :notebook, null: false, foreign_key: true

      t.timestamps

      t.index %i[number notebook_id], unique: true
    end
  end
end
