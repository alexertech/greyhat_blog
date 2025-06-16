# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Visit, type: :model do
  before do
    # Set locale to English for consistent tests
    I18n.locale = :en
  end
  
  after do
    # Reset to default locale
    I18n.locale = I18n.default_locale
  end

  describe 'associations' do
    it 'belongs to visitable polymorphic association' do
      expect(Visit.reflect_on_association(:visitable).macro).to eq(:belongs_to)
      expect(Visit.reflect_on_association(:visitable).options[:polymorphic]).to be true
    end
  end

  describe 'validations' do
    it 'requires a visitable' do
      visit = Visit.new(ip_address: '127.0.0.1')
      expect(visit).not_to be_valid
      expect(visit.errors[:visitable]).to include("can't be blank")
    end

    it 'requires an ip_address' do
      page = Page.create(name: 'test')
      visit = Visit.new(visitable: page)
      expect(visit).not_to be_valid
      expect(visit.errors[:ip_address]).to include("can't be blank")
    end

    it 'is valid with valid attributes' do
      page = Page.create(name: 'test')
      visit = Visit.new(
        visitable: page,
        ip_address: '127.0.0.1',
        user_agent: 'RSpec Test'
      )
      expect(visit).to be_valid
    end
  end

  describe 'callbacks' do
    it 'sets viewed_at to current time on create if not provided' do
      page = Page.create(name: 'test')
      visit = Visit.create(
        visitable: page,
        ip_address: '127.0.0.1'
      )
      expect(visit.viewed_at).to be_present
      expect(visit.viewed_at).to be_within(1.second).of(Time.zone.now)
    end

    it 'uses provided viewed_at if available' do
      page = Page.create(name: 'test')
      custom_time = 2.days.ago
      visit = Visit.create(
        visitable: page,
        ip_address: '127.0.0.1',
        viewed_at: custom_time
      )
      expect(visit.viewed_at).to be_within(1.second).of(custom_time)
    end
  end

  describe 'scopes' do
    let(:page) { Page.create(name: 'test') }
    
    before do
      # Create visits at different times
      Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 1.day.ago)
      Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 10.days.ago)
      Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 2.months.ago)
      Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 1.year.ago)
    end
    
    it 'returns visits from last week' do
      expect(Visit.last_week.count).to eq(1)
    end
    
    it 'returns visits from last month' do
      expect(Visit.last_month.count).to eq(2)
    end
    
    it 'returns visits from this year' do
      expect(Visit.this_year.count).to eq(3)
    end
  end

  describe '.count_by_date' do
    let(:page) { Page.create(name: 'test') }
    
    before do
      # Create visits on different days
      2.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: Date.today) }
      3.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 1.day.ago) }
      1.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 5.days.ago) }
      4.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: 10.days.ago) }
    end
    
    it 'returns count of visits grouped by date for the specified period' do
      result = Visit.count_by_date(7)
      
      expect(result).to be_a(Hash)
      # Check for today's visits
      today_count = result.find { |date, _| date.to_date == Date.today }
      expect(today_count).to be_present
      expect(today_count[1]).to eq(2)
      
      # Check for yesterday's visits
      yesterday_count = result.find { |date, _| date.to_date == 1.day.ago.to_date }
      expect(yesterday_count).to be_present
      expect(yesterday_count[1]).to eq(3)
      
      # Check for 5 days ago visits
      five_days_ago_count = result.find { |date, _| date.to_date == 5.days.ago.to_date }
      expect(five_days_ago_count).to be_present
      expect(five_days_ago_count[1]).to eq(1)
      
      # 10 days ago should not be included
      ten_days_ago_count = result.find { |date, _| date.to_date == 10.days.ago.to_date }
      expect(ten_days_ago_count).to be_nil
    end
    
    it 'uses default period of 7 days if not specified' do
      result = Visit.count_by_date
      
      expect(result.keys.count).to eq(3)
      ten_days_ago_count = result.find { |date, _| date.to_date == 10.days.ago.to_date }
      expect(ten_days_ago_count).to be_nil
    end
  end

  describe '.count_by_hour' do
    let(:page) { Page.create(name: 'test') }
    
    before do
      current_hour = Time.zone.now.hour
      
      # Create visits in different hours
      2.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: Time.zone.now) }
      3.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: Time.zone.now - 2.hours) }
      1.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: Time.zone.now - 6.hours) }
      4.times { Visit.create(visitable: page, ip_address: '127.0.0.1', viewed_at: Time.zone.now - 30.hours) }
    end
    
    it 'returns count of visits grouped by hour for the last 24 hours' do
      result = Visit.count_by_hour
      
      expect(result).to be_a(Hash)
      expect(result.keys.count).to eq(3)
      expect(result.values.sum).to eq(6)
      
      # Visits older than 24 hours are not included
      expect(result.values.sum).not_to eq(10)
    end
  end

  describe 'bot detection' do
    let(:page) { Page.create(name: 'test') }
    
    let(:bot_user_agents) do
      [
        'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        'Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)',
        'Mozilla/5.0 (compatible; YandexBot/3.0; +http://yandex.com/bots)',
        'facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)',
        'Twitterbot/1.0'
      ]
    end
    
    let(:human_user_agents) do
      [
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.114 Safari/537.36',
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1'
      ]
    end
    
    before do
      bot_user_agents.each do |agent|
        Visit.create(visitable: page, ip_address: '127.0.0.1', user_agent: agent)
      end
      
      human_user_agents.each do |agent|
        Visit.create(visitable: page, ip_address: '127.0.0.1', user_agent: agent)
      end
    end
    
    describe 'instance method' do
      it 'correctly identifies bot user agents' do
        bot_visits = Visit.where(user_agent: bot_user_agents)
        expect(bot_visits.all?(&:bot?)).to be true
      end
      
      it 'correctly identifies human user agents' do
        human_visits = Visit.where(user_agent: human_user_agents)
        expect(human_visits.none?(&:bot?)).to be true
      end
    end
    
    describe 'scopes' do
      it 'returns only bot visits with the bots scope' do
        expect(Visit.bots.count).to eq(bot_user_agents.length)
        expect(Visit.bots.pluck(:user_agent)).to match_array(bot_user_agents)
      end
      
      it 'returns only human visits with the humans scope' do
        expect(Visit.humans.count).to eq(human_user_agents.length)
        expect(Visit.humans.pluck(:user_agent)).to match_array(human_user_agents)
      end
    end
  end
  
  describe 'counter cache functionality' do
    let(:user) { create(:user) }
    let(:post) { Post.create(title: 'Test Post', body: 'Test Body', user: user) }
    let(:page) { Page.create(name: 'test_page') }
    
    it 'increments counter cache when visit is created for post' do
      initial_count = post.visits_count
      
      expect {
        Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view')
      }.to change { post.reload.visits_count }.from(initial_count).to(initial_count + 1)
    end
    
    it 'increments counter cache when visit is created for page' do
      initial_count = page.visits_count
      
      expect {
        Visit.create(visitable: page, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view')
      }.to change { page.reload.visits_count }.from(initial_count).to(initial_count + 1)
    end
    
    it 'decrements counter cache when visit is destroyed' do
      visit = Visit.create(visitable: post, ip_address: '1.1.1.1', user_agent: 'test', action_type: 'page_view')
      current_count = post.reload.visits_count
      
      expect {
        visit.destroy
      }.to change { post.reload.visits_count }.from(current_count).to(current_count - 1)
    end
    
    it 'handles counter cache correctly for different action types' do
      newsletter_visit = Visit.create(
        visitable: page, 
        ip_address: '1.1.1.1', 
        user_agent: 'test', 
        action_type: 'newsletter_click'
      )
      
      external_visit = Visit.create(
        visitable: page, 
        ip_address: '2.2.2.2', 
        user_agent: 'test', 
        action_type: 'external_link'
      )
      
      expect(page.reload.visits_count).to eq(2)
    end
  end
  
  describe 'action_type enum' do
    let(:page) { Page.create(name: 'test') }
    
    it 'defaults to page_view' do
      visit = Visit.create(visitable: page, ip_address: '1.1.1.1', user_agent: 'test')
      expect(visit.action_type).to eq('page_view')
      expect(visit.page_view?).to be true
    end
    
    it 'can be set to newsletter_click' do
      visit = Visit.create(
        visitable: page, 
        ip_address: '1.1.1.1', 
        user_agent: 'test', 
        action_type: 'newsletter_click'
      )
      expect(visit.newsletter_click?).to be true
    end
    
    it 'can be set to external_link' do
      visit = Visit.create(
        visitable: page, 
        ip_address: '1.1.1.1', 
        user_agent: 'test', 
        action_type: 'external_link'
      )
      expect(visit.external_link?).to be true
    end
  end
  
  describe 'analytics methods' do
    let(:user) { create(:user) }
    let(:post1) { Post.create(title: 'Post 1', body: 'Content', user: user, draft: false) }
    let(:post2) { Post.create(title: 'Post 2', body: 'Content', user: user, draft: false) }
    let(:newsletter_page) { Page.create(name: 'newsletter') }
    let(:index_page) { Page.create(name: 'index') }
    
    describe '.newsletter_conversion_rate' do
      before do
        # Create article visits
        3.times do |i|
          Visit.create(
            visitable: post1, 
            ip_address: "1.1.1.#{i}", 
            user_agent: 'human browser',
            action_type: 'page_view',
            viewed_at: 1.day.ago
          )
        end
        
        # Create newsletter clicks
        Visit.create(
          visitable: newsletter_page, 
          ip_address: '2.2.2.2', 
          user_agent: 'human browser',
          action_type: 'newsletter_click',
          viewed_at: 1.day.ago
        )
        
        # Create bot visit (should be excluded)
        Visit.create(
          visitable: post2, 
          ip_address: '3.3.3.3', 
          user_agent: 'Googlebot',
          action_type: 'page_view',
          viewed_at: 1.day.ago
        )
      end
      
      it 'calculates conversion rate correctly' do
        rate = Visit.newsletter_conversion_rate(7)
        # 1 newsletter click / 3 human article visits * 100 = 33.33%
        expect(rate).to be_within(0.1).of(33.33)
      end
      
      it 'returns 0 when no article visits' do
        Visit.where(visitable_type: 'Post').destroy_all
        rate = Visit.newsletter_conversion_rate(7)
        expect(rate).to eq(0)
      end
    end
    
    describe '.funnel_analysis' do
      before do
        # Clean up any existing visits from other tests
        Visit.destroy_all
        # Index visits
        2.times do |i|
          Visit.create(
            visitable: index_page, 
            ip_address: "1.1.1.#{i}", 
            user_agent: 'human browser',
            viewed_at: 1.day.ago
          )
        end
        
        # Article visits
        4.times do |i|
          Visit.create(
            visitable: post1, 
            ip_address: "2.2.2.#{i}", 
            user_agent: 'human browser',
            viewed_at: 1.day.ago
          )
        end
        
        # Newsletter page visits
        3.times do |i|
          Visit.create(
            visitable: newsletter_page, 
            ip_address: "3.3.3.#{i}", 
            user_agent: 'human browser',
            action_type: 'page_view',
            viewed_at: 1.day.ago
          )
        end
        
        # Newsletter clicks
        Visit.create(
          visitable: newsletter_page, 
          ip_address: '4.4.4.4', 
          user_agent: 'human browser',
          action_type: 'newsletter_click',
          viewed_at: 1.day.ago
        )
      end
      
      it 'returns complete funnel analysis' do
        analysis = Visit.funnel_analysis(7)
        
        expect(analysis[:index_visits]).to eq(2)
        expect(analysis[:article_visits]).to eq(4)
        expect(analysis[:newsletter_page_visits]).to eq(3)
        expect(analysis[:newsletter_clicks]).to eq(1)
        
        # Conversion rates
        expect(analysis[:index_to_articles]).to eq(200.0) # 4/2 * 100
        expect(analysis[:articles_to_newsletter]).to eq(75.0) # 3/4 * 100
        expect(analysis[:newsletter_conversion]).to be_within(0.1).of(33.3) # 1/3 * 100
      end
      
      it 'handles zero division gracefully' do
        Visit.destroy_all
        analysis = Visit.funnel_analysis(7)
        
        expect(analysis[:index_to_articles]).to eq(0)
        expect(analysis[:articles_to_newsletter]).to eq(0)
        expect(analysis[:newsletter_conversion]).to eq(0)
      end
    end
  end
end
