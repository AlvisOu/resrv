source 'https://rubygems.org'

ruby '3.3.8'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '8.0'
# JS engine
gem 'mini_racer', platforms: :ruby
# Use Puma as the app server
gem 'puma'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use jquery as the JavaScript library
gem 'jquery-rails'
# Encryption and security
gem 'bcrypt'
# Window support
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]
# Slug generation
gem "friendly_id", "~> 5.4"


group :development, :test do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '~> 2.1'
  # Testing framework
  gem 'rspec-rails'
  gem 'guard-rspec'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  # Email sending in development
  gem 'letter_opener'
end

group :development do
  # Utility gems
  gem 'rename'
end

group :test do
  # BDD framework
  gem 'cucumber-rails', require: false
  # Cleans database between test runs
  gem 'database_cleaner-active_record'
  # Test coverage analysis
  gem 'simplecov', require: false
  # Back controller testing support
  gem 'rails-controller-testing'
  # High level browser emulation for Cucumber
  gem "selenium-webdriver"
end

group :production do
  # Database for production
  gem 'pg', '~> 1.1'
  gem 'rails_12factor'
end

