class ChangeShifts < ActiveRecord::Migration
  def up
    change_column_default :users, :shifts, nil
    change_column :users, :shifts, :text

    shifts = User.all.map { |u| { id: u.id, shift: u.shifts } }
    shifts.each do |hash|
      sliced = (hash[:shift].blank? ? hash[:shift] : User::DEFAULT_SHIFTS).each_slice(3)
      result = Shifts.new
      result.each_key do |key| 
        result[key].concat sliced.map { |args| Shift.new(*args) }
      end
      u = User.find(hash[:id])
      u.update_attributes shifts: result
      u.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
