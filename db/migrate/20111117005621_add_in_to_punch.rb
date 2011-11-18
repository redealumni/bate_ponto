class AddInToPunch < ActiveRecord::Migration
  def change
    add_column :punches, :entrance, :boolean, :default => true
  end
end
