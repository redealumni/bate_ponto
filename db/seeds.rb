# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
users =
[
  User.create!(name:'Admin', password: 'abc123', token: '123', admin: true),
  User.create!(name:'Uni', password: 'abc123', token: '234'),
  User.create!(name:'Duni', password: 'abc123', token: '345'),
  User.create!(name:'Te', password: 'abc123', token: '456')
]

date_range = Time.parse('2012-10-01').to_date..Date.yesterday
punch_hours = [8.hours, 12.hours, 14.hours, 18.hours]

def oops
  rand(-45..45).minutes
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