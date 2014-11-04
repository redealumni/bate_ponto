class UpdateUsersShifts < ActiveRecord::Migration
  def change
    User.find_each do |user|
      user.shifts = Shifts.new_default
      user.save
    end
  end
end
