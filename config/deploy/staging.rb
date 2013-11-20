set :deploy_to, "/home/grevalis/www/idocus/staging"
set :branch, "develop"
set :rails_env, "staging"

namespace :git do
  desc "Push code to local and origin"
  task :push, :roles => :app do
    %x(git push local develop)
    %x(git push origin develop)
  end
end