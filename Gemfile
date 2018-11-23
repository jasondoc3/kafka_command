source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'rubocop-rails_config'
  gem 'rubocop-rspec'
end

group :test do
  # rspec is badass
  gem 'rspec-rails'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
end

