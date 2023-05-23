source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.4"

gem "rails", "7.0.4.3"
gem "pg", "~> 1.4"
gem "puma", "~> 5.0"
gem "turbolinks", "~> 5"
gem "jbuilder", "~> 2.7"
gem 'sass-rails'
gem "devise", "4.8.1"
gem "font-awesome-rails"
gem "bootsnap", ">= 1.4.2", require: false

# Markdown Support with CodeStyling
gem "redcarpet", "~> 3.5.1"
gem "coderay", "~> 1.1.3"

# Recaptcha
gem "recaptcha", "~> 5.12.3"

# Code styling
gem "prettier", "~> 3.2"

# Read .env files
gem "dotenv-rails"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem "web-console", ">= 3.3.0"
  gem "listen", ">= 3.0.5", "< 3.2"
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem "spring"
  gem "spring-watcher-listen", "~> 2.0.0"
end