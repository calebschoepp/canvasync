class CreateNotebooks < ActiveRecord::Migration[7.1]
  def change
    create_table :notebooks do |t|
      t.text :name

      t.timestamps
    end
  end
end
