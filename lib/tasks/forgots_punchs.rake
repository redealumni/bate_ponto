namespace :forgot_punch do
  desc "Checks if has punched forgoten"
  task :forgot => :environment do
    User.find_each do |user|
      user.forgot_punch?
    end
  end
end

