# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.4'

gem 'bootsnap', '~> 1.18', '>= 1.18.4', require: false
gem 'devise', '4.9.4'
gem 'image_processing', '~> 1.2'
gem 'jbuilder', '~> 2.7'
gem 'pg', '~> 1.4'
gem 'puma', '~> 6.6'  
gem 'rails', '7.2.2.1'
gem 'sass-rails'
gem 'turbolinks', '~> 5'

# Javascript
gem 'stimulus-rails'
gem 'actiontext'
gem 'importmap-rails'
gem 'bootstrap', '~> 5.3.0'
gem 'sassc-rails'

# Markdown Support with CodeStyling
gem 'coderay', '~> 1.1.3'
gem 'redcarpet', '~> 3.5.1'

# Recaptcha
gem 'recaptcha', '~> 5.12.3'

# Code styling
gem 'prettier', '~> 3.2'

# Read .env files
gem 'dotenv-rails'

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem 'sprockets-rails'

gem 'bcrypt_pbkdf', '~> 1.1', '>= 1.1.1'
gem 'capistrano', '~> 3.19', '>= 3.19.1'
gem 'capistrano-bundler', '~> 2.1'
gem 'capistrano-rails', '~> 1.6', '>= 1.6.3'
gem 'capistrano-rails-console', '~> 2.3'
gem 'capistrano-rbenv', '~> 2.2'
gem 'ed25519', '~> 1.3'
gem 'net-ssh', '~> 7.2', '>= 7.2.3'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'rubocop'
  gem 'rails-controller-testing'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'web-console', '>= 3.3.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'rspec-rails', '~> 6.0', '>= 6.0.3'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end
