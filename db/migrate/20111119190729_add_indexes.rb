class AddIndexes < ActiveRecord::Migration
  def up
    add_index :punches, :punched_at
    add_index :punches, :user_id
    add_index :punches, :entrance
  end

  def down
    remove_index :punches, :punched_at
    remove_index :punches, :user_id
    remove_index :punches, :entrance
  end
end
