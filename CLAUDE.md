# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Start server: `bundle exec rails s`
- Install dependencies: `bundle install`
- Database setup: `bundle exec rails db:prepare`
- Run all tests: `bundle exec rspec`
- Run single test: `bundle exec rspec spec/path/to_spec.rb:LINE_NUMBER`
- Deploy: `bundle exec cap production deploy`

## Code Style Guidelines
- Ruby: Use frozen_string_literal for all Ruby files
- Follow Rails naming conventions (snake_case for variables/methods, CamelCase for classes)
- Model validation and callbacks at the top of class definitions
- JS: Use Stimulus for JavaScript behavior
- CSS: Use existing classes when possible
- Use PostgreSQL for database features
- Error handling with Rails standard rescue_from in controllers
- Handle form validation with model validations and appropriate error rendering

## Dependencies
- Devise for authentication
- Capistrano for deployment
- RSpec for testing
- Markdown with Redcarpet and CodeRay for syntax highlighting
- Stimulus for JavaScript components