## User information
set :runner, "rails"
set :user, "rails"
set :use_sudo, false
set :rails_env, "production"

set :deploy_to, "/home/rails/www/idocus"
set :branch, "production"

## Server information
role :app, "ec2-79-125-95-142.eu-west-1.compute.amazonaws.com"
role :app, "ec2-79-125-89-22.eu-west-1.compute.amazonaws.com"

role :web, "ec2-79-125-95-142.eu-west-1.compute.amazonaws.com"
role :web, "ec2-79-125-89-22.eu-west-1.compute.amazonaws.com"

role :db, "ec2-79-125-95-142.eu-west-1.compute.amazonaws.com", :primary => true
role :db, "ec2-79-125-89-22.eu-west-1.compute.amazonaws.com"

