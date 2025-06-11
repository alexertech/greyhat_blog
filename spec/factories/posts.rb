# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    sequence(:title) { |n| "Test Post #{n}" }
    body { ActionText::Content.new("This is the body content for the post.") }
    draft { false }
    sequence(:slug) { |n| "test-post-#{n}" }
    association :user
    
    trait :draft do
      draft { true }
    end
    
    trait :published do
      draft { false }
    end
    
    trait :with_image do
      after(:build) do |post|
        post.image.attach(
          io: StringIO.new("fake image content"),
          filename: 'test-image.jpg',
          content_type: 'image/jpeg'
        )
      end
    end
    
    trait :with_tags do
      after(:create) do |post|
        post.tags << create_list(:tag, 2)
      end
    end
  end
end