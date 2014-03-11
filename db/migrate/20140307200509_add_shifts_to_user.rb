class AddShiftsToUser < ActiveRecord::Migration
  def change
    add_column :users, :shifts, :string, null: false, default: User::DEFAULT_SHIFTS.to_yaml
  end
end
