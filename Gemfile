source 'http://rubygems.org'

ruby "2.0.0"

gem 'rails', '4.0.3'

# Gems used only for assets and not required
# in production environments by default.

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

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'

group :development, :production do
  gem 'mysql2'
end

group :development, :test do
  #gem 'debugger'
  gem 'pry-rails'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'test-unit'
end
