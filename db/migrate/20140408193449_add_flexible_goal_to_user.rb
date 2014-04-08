class AddFlexibleGoalToUser < ActiveRecord::Migration
  def change
    add_column :users, :flexible_goal, :boolean, default: false
  end
end
