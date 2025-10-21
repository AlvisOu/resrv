source 'https://rubygems.org'

ruby '3.3.8'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '8.0'

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use jquery as the JavaScript library
gem 'jquery-rails'


# Use Unicorn as the app server
# gem 'unicorn'

gem 'themoviedb'

# Window support
gem 'tzinfo'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  gem 'rspec-rails'
  gem 'guard-rspec'

  # Use sqlite3 as the database for Active Record
  gem 'sqlite3', '~> 2.1'

end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  # gem 'web-console', '~> 2.0'
end

group :production do
  gem 'pg', '~> 1.1' # for Heroku deployment
  gem 'rails_12factor'
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_cleaner-active_record'
  gem 'simplecov', require: false
end