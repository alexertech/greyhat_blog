# frozen_string_literal: true

FactoryBot.define do
  factory :contact do
    sequence(:name) { |n| "John Smith" }
    sequence(:email) { |n| "contact#{n}@example.com" }
    message { "Hello, I would like to get in touch about your services. I'm interested in learning more about what you offer." }
    
    trait :short_message do
      message { "Please contact me." }
    end
    
    trait :detailed_message do
      message { "I'm reaching out regarding your development services. I have a project that involves building a web application with Ruby on Rails and would appreciate discussing the requirements and timeline. Please let me know when would be a good time to connect." }
    end
    
    trait :business_inquiry do
      name { "Business Manager" }
      email { "manager@company.com" }
      message { "We're interested in your consulting services for our upcoming digital transformation project. Could we schedule a call to discuss our requirements?" }
    end
    
    trait :with_suspicious_email do
      email { "user@temp-mail.org" }
      message { "Quick question" }
    end
    
    trait :spam_like do
      name { "Spammer" }
      email { "spam@mail.com" }
      message { "Buy now!" }
    end
  end
end