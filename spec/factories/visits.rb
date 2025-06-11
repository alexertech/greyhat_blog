# frozen_string_literal: true

FactoryBot.define do
  factory :visit do
    association :visitable, factory: :post
    ip_address { "192.168.1.#{rand(1..254)}" }
    user_agent { "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" }
    referer { "https://example.com/#{rand(1000..9999)}" }
    viewed_at { Time.current }
    action_type { 'page_view' }
    
    trait :bot do
      user_agent { "Googlebot/2.1 (+http://www.google.com/bot.html)" }
    end
    
    trait :human do
      user_agent { "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" }
    end
    
    trait :newsletter_click do
      action_type { 'newsletter_click' }
    end
    
    trait :external_link do
      action_type { 'external_link' }
    end
    
    trait :from_search_engine do
      referer { "https://www.google.com/search?q=technology+blog" }
    end
    
    trait :direct_visit do
      referer { nil }
    end
    
    trait :social_media do
      referer { "https://twitter.com/user/status/123456789" }
    end
    
    trait :this_week do
      viewed_at { rand(1.week.ago..Time.current) }
    end
    
    trait :last_week do
      viewed_at { rand(2.weeks.ago..1.week.ago) }
    end
    
    trait :this_month do
      viewed_at { rand(1.month.ago..Time.current) }
    end
    
    trait :for_page do
      association :visitable, factory: :page
    end
  end
end