# frozen_string_literal: true

FactoryBot.define do
  factory :page do
    sequence(:name) { |n| "page-#{n}" }
    sequence(:title) { |n| "Page Title #{n}" }
    content { "This is the content for the page." }
    unique_visits { 0 }
    
    trait :index_page do
      name { "index" }
      title { "Home Page" }
      content { "Welcome to our blog!" }
    end
    
    trait :about_page do
      name { "about" }
      title { "About Us" }
      content { "Learn more about our blog and mission." }
    end
    
    trait :newsletter_page do
      name { "newsletter" }
      title { "Newsletter" }
      content { "Subscribe to our newsletter for updates." }
    end
    
    trait :services_page do
      name { "services" }
      title { "Services" }
      content { "Our professional services." }
    end
    
    trait :contact_page do
      name { "contact" }
      title { "Contact" }
      content { "Get in touch with us." }
    end
  end
end