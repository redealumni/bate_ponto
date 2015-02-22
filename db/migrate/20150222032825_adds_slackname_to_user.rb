class AddsSlacknameToUser < ActiveRecord::Migration
  def change
    add_column :users, :slack_username, :string, default: ""
  end
end
