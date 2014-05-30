# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

shift_cfg = Shifts.new_default
users =
[
  User.create!(name:'Admin', password: 'abc123', token: '123', admin: true, shifts: shift_cfg),
  User.create!(name:'Uni', password: 'abc123', token: '234', shifts: shift_cfg),
  User.create!(name:'Duni', password: 'abc123', token: '345', shifts: shift_cfg),
  User.create!(name:'Te', password: 'abc123', token: '456', shifts: shift_cfg)
]

anotherday = Date.yesterday - 1.day

date_range = Time.parse('2013-10-01').to_date..anotherday
punch_hours = [8.hours, 12.hours, 14.hours, 18.hours]

def oops
  rand(-15..15).minutes
end

date_range.each do |date|
  users.each do |user|
    punch_hours.each do |punch_time|
      punch = Punch.create!(user: user, punched_at: date.midnight + punch_time + oops)
      punch.created_at = punch.updated_at = punch.punched_at
      punch.save!
    end
  end
end

users.each do |user|
  punch_hours[0, 3].each do |punch_time|
    punch = Punch.create!(user: user, punched_at: Date.yesterday.midnight + punch_time + oops)
    punch.created_at = punch.updated_at = punch.punched_at
    punch.save!
  end
end

Delayed::Job.delete_all