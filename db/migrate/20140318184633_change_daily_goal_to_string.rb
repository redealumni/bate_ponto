class ChangeDailyGoalToString < ActiveRecord::Migration
  def change
    add_column :users, :goals, :string, null: false, default: YAML.dump([8] * 5)
    remove_column :users, :daily_goal
  end
end
