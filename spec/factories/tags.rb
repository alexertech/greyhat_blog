# frozen_string_literal: true

FactoryBot.define do
  factory :tag do
    sequence(:name) { |n| "tag#{n}" }
    
    trait :ruby do
      name { 'ruby' }
    end
    
    trait :javascript do
      name { 'javascript' }
    end
    
    trait :popular do
      after(:create) do |tag|
        create_list(:post, 3, :published, tags: [tag])
      end
    end
  end
end