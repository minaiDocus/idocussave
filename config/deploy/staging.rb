set :deploy_to, '/home/deploy/staging'

set :linked_dirs, fetch(:linked_dirs, []).push('files')

set :repo_url, 'git@github.com:i-docus/main.git'

set :branch, 'upgrade-rails5'

set :rvm_ruby_version, '2.6.5'

server 'staging-rails5.idocus.com', user: 'deploy', roles: %w{app db web}
