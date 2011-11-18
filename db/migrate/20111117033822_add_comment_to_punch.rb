class AddCommentToPunch < ActiveRecord::Migration
  def change
    add_column :punches, :comment, :text
  end
end
