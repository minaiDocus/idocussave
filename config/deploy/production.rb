set :deploy_to, '/data/idocus/deploy/production'

set :linked_dirs, fetch(:linked_dirs, []).push('files')

set :repo_url, 'git@github.com:i-docus/main.git'

set :branch, 'master'

set :rvm_ruby_version, '2.6.5'

server 'legacy.idocus.com', user: 'idocus', roles: %w{app db web}

namespace :deploy do
  after :updated, :link_production_data do
    on roles(:all) do
      execute "ln -s /data/idocus/production_data/files #{release_path}/files"
    end
  end
end