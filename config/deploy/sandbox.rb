set :deploy_to, '/data/idocus/deploy/sandbox'

set :branch, `git rev-parse --abbrev-ref HEAD`.strip

set :linked_dirs, fetch(:linked_dirs, []).push('files')

set :repo_url, 'git@github.com:dbarbarossa/idocusave.git'

set :branch, 'staging'

set :rvm_ruby_version, '2.3.1'

server 'www.idocus.com', user: 'idocus', roles: %w{app db web}
