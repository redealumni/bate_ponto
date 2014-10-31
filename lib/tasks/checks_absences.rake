namespace :check_absences do
  desc "Checks abscenses from yesterday until today"
  task :yesterday => :environment do
    User.all.each do |user|
      user.missed_the_day?(Time.zone.yesterday)
    end
  end
end

