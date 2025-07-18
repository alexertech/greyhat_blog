# frozen_string_literal: true

set :application, 'greyhat_cl'
set :repo_url, 'git@tharpa.khyungnorbu.duckdns.org:alexertech/alexertech_com.git'
set :deploy_to, '/home/alex/greyhat_cl'

set :rbenv_ruby, File.read('.ruby-version').strip
set :rbenv_path, '$HOME/.rbenv/'
set :bundle_binstubs, nil
set :default_env, path: '~/.rbenv/shims:~/.rbenv/bin:$PATH'
set :default_environment, 'PATH' => '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH'

set :linked_files, %w[config/database.yml config/master.key config/credentials.yml.enc]
set :linked_dirs, %w[storage log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]

namespace :deploy do
  desc 'Run database migrations'
  task :migrate do
    on roles(:db) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :rails, 'db:migrate'
        end
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  # Run migrations before restarting the app
  after :updated, 'deploy:migrate'
  after :publishing, 'deploy:restart'
  after :finishing, 'deploy:cleanup'
end
