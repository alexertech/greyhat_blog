# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:public_name) { |n| "User #{n}" }
    password { 'password123456' }
    password_confirmation { 'password123456' }
    description { 'Test user description' }
  end
end