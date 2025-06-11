# frozen_string_literal: true

FactoryBot.define do
  factory :comment do
    association :post
    sequence(:username) { |n| "John Doe" }
    sequence(:email) { |n| "user#{n}@example.com" }
    body { "This is a great article! Thanks for sharing your insights about technology and development." }
    approved { false }
    
    trait :approved do
      approved { true }
    end
    
    trait :pending do
      approved { false }
    end
    
    trait :short_comment do
      body { "Great post!" }
    end
    
    trait :long_comment do
      body { "This is an excellent article that provides deep insights into the subject matter. I particularly enjoyed the technical details and the practical examples provided. Keep up the great work!" }
    end
    
    trait :spam_like do
      username { "SpamUser" }
      email { "spam@spam.com" }
      body { "Buy cheap products now! Click here for amazing deals!" }
    end
  end
end