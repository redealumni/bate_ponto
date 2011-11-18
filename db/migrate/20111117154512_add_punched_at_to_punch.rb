class AddPunchedAtToPunch < ActiveRecord::Migration
  def change
    add_column :punches, :punched_at, :datetime
  end
end
