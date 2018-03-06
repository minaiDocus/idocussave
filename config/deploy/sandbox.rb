set :deploy_to, '/data/idocus/deploy/sandbox'
set :branch, `git rev-parse --abbrev-ref HEAD`.strip
set :linked_dirs, fetch(:linked_dirs, []).push('files')
