source 'http://rubygems.org'

ruby "2.1.2"

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
  gem 'pg'
end

group :development, :test do
  gem 'thin'
  gem 'pry-rails'
  gem 'byebug'
  gem 'pry-byebug'
end

group :test do
  gem 'fivemat'
  gem 'test-unit'
  gem 'timecop'
end
