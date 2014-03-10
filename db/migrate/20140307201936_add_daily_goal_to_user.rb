class AddDailyGoalToUser < ActiveRecord::Migration
  def change
    add_column :users, :daily_goal, :integer, null: false, default: 8
  end
end
