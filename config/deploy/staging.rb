set :deploy_to, "/home/grevalis/www/idocus/staging"
set :branch, $1 if `git branch` =~ /\* (\S+)\s/m
set :rails_env, "staging"
set :rack_env, "staging"

namespace :git do
  desc "Push code to origin"
  task :push, :roles => :app do
    %x(git push origin #{branch})
  end
end
