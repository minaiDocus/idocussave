set :deploy_to, '/home/deploy/main/'

set :repo_url, 'git@github.com:i-docus/main.git'

set :branch, 'master'

set :rvm_ruby_version, '2.6.5'

server 'app-1.idocus.tech', user: 'deploy', roles: %w{app db web}
server 'app-2.idocus.tech', user: 'deploy', roles: %w{app web}
server 'sidekiq-1.idocus.tech', user: 'deploy', roles: %w{app worker}
server 'sidekiq-2.idocus.tech', user: 'deploy', roles: %w{app worker}

