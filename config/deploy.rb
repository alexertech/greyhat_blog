# frozen_string_literal: true

set :application, 'greyhat_blog'
set :repo_url, 'git@github.com:alexertech/greyhat_blog.git'
set :deploy_to, '/home/alex/greyhat_blog'

set :linked_files, %w[config/database.yml]
set :linked_dirs, %w[log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]

namespace :deploy do
  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end
