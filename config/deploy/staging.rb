set :user, "rails"
set :runner, "rails"
set :use_sudo, false
set :rails_env, "staging"

set :deploy_to, "/home/rails/www/idocus"
set :branch, "staging"

role :app, "staging.novelys.com", :primary => true
role :web, "staging.novelys.com", :primary => true
role :db,  "staging.novelys.com", :primary => true

