namespace :ponto do
  desc "Fix goals"
  task :fix_goals => :environment do
    User.find_each do |user|
      user.goals.fill(0, user.goals.size...6)
      user.save!
    end
  end
end

