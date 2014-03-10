class AddShiftsToUser < ActiveRecord::Migration
  def change
    add_column :users, :shifts, :string
  end
end
