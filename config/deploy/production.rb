# frozen_string_literal: true

set :stage, :production
server '104.248.230.101', port: 7822, user: 'alex', roles: %w[web app]
