source 'http://rubygems.org'

gem 'rails', '3.2.11'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'
gem 'bourbon'
gem 'will_paginate'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

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
  gem 'debugger'
end

group :test do
  # Pretty printed test output
  gem 'turn', :require => false
  gem 'test-unit'
end
