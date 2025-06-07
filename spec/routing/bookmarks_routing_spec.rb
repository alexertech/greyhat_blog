# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BookmarksController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/guardados').to route_to('bookmarks#index')
    end

    it 'generates the correct path' do
      expect(bookmarks_path).to eq('/guardados')
    end
  end
end