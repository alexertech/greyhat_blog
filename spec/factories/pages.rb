# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    sequence(:name) { |n| "page-#{n}" }
    unique_visits { 0 }
    
    trait :index_page do
      name { "index" }
    end

    trait :about_page do
      name { "about" }
    end

    trait :newsletter_page do
      name { "newsletter" }
    end

    trait :services_page do
      name { "services" }
    end

    trait :contact_page do
      name { "contact" }
    end
  end
end