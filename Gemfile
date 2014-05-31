source 'http://rubygems.org'

ruby "2.0.0"

gem 'rails', '~> 4.1.0'

# Rails 4 doesn't support the assets group anymore
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'compass-rails'
gem 'zurb-foundation'

gem 'jquery-rails'
gem 'will_paginate'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby'

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

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

group :development, :production do
  gem 'mysql2'
end

group :development, :test do
  gem 'thin'
  gem 'pry-rails'
  gem 'byebug'
  gem 'pry-byebug'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'test-unit'
end
