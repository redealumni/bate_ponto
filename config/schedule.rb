# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

timezone_offset_in_hours = -3
midnight_in_brazil       = Time.parse('0 am') + timezone_offset_in_hours.hours
# Disable...
# every 1.day, at: midnight_in_brazil + 3.hours do
#   runner 'Punch.maintenance'
# end
every 1.day at: '8:00 am' do
  rake "check_absences:yesterday"
end