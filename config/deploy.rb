# frozen_string_literal: true

set :application, 'greyhat_cl'
set :repo_url, 'git@github.com:alexertech/greyhat_blog.git'
set :deploy_to, '/home/alex/greyhat_cl'

set :rbenv_ruby, File.read('.ruby-version').strip
set :rbenv_path, '$HOME/.rbenv/'
set :bundle_binstubs, nil
set :default_env, path: '~/.rbenv/shims:~/.rbenv/bin:$PATH'
set :default_environment, 'PATH' => '$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH'

set :linked_files, %w[config/database.yml config/master.key config/credentials.yml.enc]
set :linked_dirs, %w[storage log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system]

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
