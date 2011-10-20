set :application, "idocus"
set :repository,  "git@github.com:novelys/idocus"

set :keep_releases, 5

set :scm, "git"
set :repository_cache, "git_cache"
set :copy_exclude, [".svn", ".DS_Store", ".git"]
ssh_options[:forward_agent] = true

require 'capistrano/ext/multistage'
require 'hoptoad_notifier/capistrano'

set :stages, %w(staging)

after "deploy:update_code", "db:symlink", "bundler:create_symlink", "bundler:bundle_new_release"
after "deploy:setup", "db:mkdir"
after "deploy", "deploy:cleanup"

namespace :db do
  desc "Make symlink for database yaml"
  task :symlink do
    run "ln -nfs #{shared_path}/config/mongoid.yml #{current_release}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/config/amazon_s3.yml #{current_release}/config/amazon_s3.yml"
    run "ln -nfs #{shared_path}/config/paypal.yml #{current_release}/config/paypal.yml"
  end

  desc "Create necessary directories"
  task :mkdir do
    run "mkdir -p #{shared_path}/config"
  end
end


namespace :mod_rails do
  desc <<-DESC
  Restart the application altering tmp/restart.txt for mod_rails.
  DESC
  task :restart, :roles => :app do
    run "touch  #{current_release}/tmp/restart.txt"
  end
end

namespace :deploy do
  %w(start restart).each { |name| task name, :roles => :app do mod_rails.restart end }

  desc "print revision number in admin template"
  task :print_revision do
    rake = fetch(:rake, "rake")
    rails_env = fetch(:rails_env, "development")
    run "cd #{release_path} && RAILS_ENV=#{rails_env} SVN_REVISION=#{real_revision.to_s[0,6]} #{rake} revision:print"
  end
end

namespace :deploy do
  desc "Update the crontab file"
  task :update_crontab, :roles => :db do
    run "cd #{current_release} && RAILS_ENV=#{rails_env} whenever --update-crontab #{application}"
  end
end

namespace :bundler do
  task :create_symlink, :roles => :app do
    set :bundle_dir, File.join(release_path, 'vendor', 'bundle')

    shared_dir = File.join(shared_path, 'bundle')
    run "rm -rf #{bundle_dir}"
    run "mkdir -p #{shared_dir} && ln -s #{shared_dir} #{bundle_dir}"
  end

  task :bundle_new_release, :roles => :app do
    bundler.create_symlink
    run "cd #{release_path} ; bundle install --deployment --without development test"
  end
end

namespace :delayed_job do
  desc "Start delayed_job process"
  task :start, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job start"
  end

  desc "Stop delayed_job process"
  task :stop, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job stop"
  end

  desc "Restart delayed_job process"
  task :restart, :roles => :app do
    run "cd #{current_path}; RAILS_ENV=#{rails_env} script/delayed_job restart"
  end
end

