class AddFailedToExports < ActiveRecord::Migration[7.1]
  def change
    add_column :exports, :failed, :boolean
  end
end
