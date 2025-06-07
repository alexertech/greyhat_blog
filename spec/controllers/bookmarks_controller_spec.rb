# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookmarksController, type: :controller do
  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end

    it 'renders the index template' do
      get :index
      expect(response).to render_template(:index)
    end

    it 'returns 200 status code' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end
end