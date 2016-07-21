source 'http://rubygems.org'

ruby "2.1.6"

gem 'rails', '~> 4.1.0'

# Rails 4 doesn't support the assets group anymore
gem 'sass-rails'
gem 'compass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'zurb-foundation'

gem 'jquery-rails'
gem 'will_paginate'

# To use ActiveModel has_secure_password
gem 'bcrypt'

# To generate reports
gem 'wkhtmltopdf-binary'
gem 'wicked_pdf'

# To generate zip files
gem 'rubyzip'

# Time picker
gem 'jquery-timepicker-rails'

# Cron
gem 'whenever'

# Background jobs
gem 'delayed_job_active_record'

# Slack notifications
gem 'slack-notifier'

# Robots.txt
gem 'roboto'

# Render Anywhere
gem 'render_anywhere'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'
gem 'tzinfo-data'

group :development, :production do
  gem 'pg'
end

group :development, :test do
  gem 'thin'
  gem 'pry-rails'
  gem 'byebug'
  gem 'pry-byebug'
  # gem 'therubyracer' # for vagrant
end

group :test do
  gem 'fivemat'
  gem 'test-unit'
  gem 'timecop'
end
