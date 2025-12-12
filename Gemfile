# frozen_string_literal: true

source 'https://rubygems.org'

ruby file: '.ruby-version'

# Core
gem 'rails', '8.1.1'
gem 'pg'
gem 'puma'
gem 'bootsnap', require: false

# Frontend
gem 'propshaft'
gem 'importmap-rails'
gem 'turbo-rails'
gem 'stimulus-rails'
gem 'bootstrap', '~> 5.3'
gem 'dartsass-rails'

# Rich text and storage
gem 'actiontext'
gem 'image_processing'

# Authentication
gem 'devise'

# Content
gem 'redcarpet'
gem 'coderay'
gem 'will_paginate'
gem 'will_paginate-bootstrap4'

# Background jobs
gem 'good_job'

# Charts and analytics
gem 'chartkick'

# Utilities
gem 'jbuilder'
gem 'dotenv-rails'
gem 'recaptcha'

# Deployment (Capistrano)
gem 'capistrano'
gem 'capistrano-rails'
gem 'capistrano-bundler'
gem 'capistrano-rbenv'
gem 'capistrano-rails-console'
gem 'ed25519'
gem 'bcrypt_pbkdf'
gem 'net-ssh'

group :development, :test do
  gem 'debug'
  gem 'rspec-rails'
  gem 'factory_bot_rails'
  gem 'faker'
  gem 'rails-controller-testing'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'rubocop', require: false
  # gem 'bullet' # Disabled until Rails 8.1 support
end

group :development do
  gem 'web-console'
end
