# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PagesController, type: :controller do
  describe 'GET #index' do
    it 'returns a successful response' do
      page = Page.create(id: 1, name: 'index')
      get :index
      expect(response).to be_successful
    end

    it 'assigns @page' do
      page = Page.create(id: 1, name: 'index')
      get :index
      expect(assigns(:page)).to eq(page)
    end
    
    it 'tracks the visit' do
      page = Page.create(id: 1, name: 'index', unique_visits: 0)
      expect {
        get :index
      }.to change { page.reload.unique_visits }.by(1)
      
      expect(page.visits.count).to eq(1)
      expect(page.visits.last.ip_address).to be_present
      expect(page.visits.last.user_agent).to be_present
    end

    it 'does not increment unique visits for same IP within 24 hours' do
      page = Page.create(id: 1, name: 'index', unique_visits: 0)
      
      # First visit
      get :index
      expect(page.reload.unique_visits).to eq(1)
      
      # Second visit from same IP should not increment unique_visits
      expect {
        get :index
      }.not_to change { page.reload.unique_visits }
      
      # But should still create a visit record
      expect(page.visits.count).to eq(2)
    end
  end

  describe 'GET #about' do
    it 'returns a successful response' do
      page = Page.create(id: 2, name: 'about')
      get :about
      expect(response).to be_successful
    end

    it 'assigns @page' do
      page = Page.create(id: 2, name: 'about')
      get :about
      expect(assigns(:page)).to eq(page)
    end
    
    it 'tracks the visit' do
      page = Page.create(id: 2, name: 'about', unique_visits: 0)
      expect {
        get :about
      }.to change { page.reload.unique_visits }.by(1)
      
      expect(page.visits.count).to eq(1)
    end
  end

  describe 'GET #services' do
    it 'returns a successful response' do
      page = Page.create(id: 3, name: 'services')
      get :services
      expect(response).to be_successful
    end

    it 'assigns @page' do
      page = Page.create(id: 3, name: 'services')
      get :services
      expect(assigns(:page)).to eq(page)
    end
    
    it 'tracks the visit' do
      page = Page.create(id: 3, name: 'services', unique_visits: 0)
      expect {
        get :services
      }.to change { page.reload.unique_visits }.by(1)
      
      expect(page.visits.count).to eq(1)
    end
  end
end 