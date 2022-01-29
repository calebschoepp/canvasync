class CreateUserNotebooks < ActiveRecord::Migration[7.1]
  def change
    create_table :user_notebooks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :notebook, null: false, foreign_key: true
      t.boolean :is_owner

      t.timestamps
    end
  end
end
