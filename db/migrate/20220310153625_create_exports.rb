class CreateExports < ActiveRecord::Migration[7.1]
  def change
    create_table :exports do |t|
      t.references :notebook, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.boolean :ready

      t.timestamps
    end
  end
end
