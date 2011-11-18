class CreatePunches < ActiveRecord::Migration
  def change
    create_table :punches do |t|
      t.integer :user_id

      t.timestamps
    end
  end
end
