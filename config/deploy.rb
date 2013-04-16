set :rvm_ruby_string, '1.9.3'
require "rvm/capistrano"

default_run_options[:pty] = true
#ssh_options[:forward_agent] = true

set :runner, "rails"
set :normalize_asset_timestamps, false
set :user, "grevalis"
set :use_sudo, false
set :rails_env, "production"

set :application, "idocus"

set :keep_releases, 5

set :repository, "git@github.com:ftachot/idocus.git"
set :local_repository, "~/git/repositories/idocus.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache
set :repository_cache, "git_cache"
set :copy_exclude, [".svn", ".DS_Store", ".git"]

role :app, "grevalis.alwaysdata.net"

set :stages, %w(production staging sandbox)
require 'capistrano/ext/multistage'

before "deploy", "worker:stop", "delayed_job:stop", "deploy:setup", "shared:mkdir"
before "deploy:update", "git:push"
after "deploy:finalize_update", "shared:config"
before "deploy:symlink", "shared:symlink"
after "deploy", "deploy:cleanup", "worker:start", "delayed_job:start"

def remote_file_exist?(filepath)
  'true' == capture("if [ -e #{filepath} ]; then echo 'true'; fi").strip
end

namespace :shared do
  desc "Make symlink"
  task :symlink do
    run "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    run "ln -nfs #{shared_path}/config/initializers/address_delivery_list.rb #{release_path}/config/initializers/address_delivery_list.rb"
    run "ln -nfs #{shared_path}/config/initializers/notification.rb #{release_path}/config/initializers/notification.rb"
    run "ln -nfs #{shared_path}/config/initializers/num.rb #{release_path}/config/initializers/num.rb"
    run "ln -nfs #{shared_path}/config/initializers/compta.rb #{release_path}/config/initializers/compta.rb"
    run "ln -nfs #{shared_path}/config/initializers/site.rb #{release_path}/config/initializers/site.rb"
    run "ln -nfs #{shared_path}/config/initializers/fix_ssl.rb #{release_path}/config/initializers/fix_ssl.rb"
    run "ln -nfs #{shared_path}/public/system #{release_path}/public/system"
    run "ln -s #{shared_path}/data #{release_path}/data"
    run "ln -s #{shared_path}/files #{release_path}/files"
  end

  desc "Create necessary directories"
  task :mkdir do
    run "mkdir -p #{shared_path}/config/initializers"
    run "mkdir -p #{shared_path}/public/system"
    run "mkdir -p #{current_release}/tmp"
    run "mkdir -p #{shared_path}/data/compta/mapping"
    run "mkdir -p #{shared_path}/files/tmp/uploads"
    run "mkdir -p #{shared_path}/files/tmp/DELIVERY_BACKUP"
    run "mkdir -p #{shared_path}/files/kit"
    run "mkdir -p #{shared_path}/files/attachments/archives"
    run "mkdir -p #{shared_path}/files/compositions"
  end

  desc "Prepare config files"
  task :config do
    if remote_file_exist? "#{shared_path}/config/initializers/notification.rb"
      run "rm #{release_path}/config/initializers/notification.rb"
    else
      run "mv #{release_path}/config/initializers/notification.rb #{shared_path}/config/initializers"
    end
    if remote_file_exist? "#{shared_path}/config/initializers/num.rb"
      run "rm #{release_path}/config/initializers/num.rb"
    else
      run "mv #{release_path}/config/initializers/num.rb #{shared_path}/config/initializers"
    end
    if remote_file_exist? "#{shared_path}/config/initializers/compta.rb"
      run "rm #{release_path}/config/initializers/compta.rb"
    else
      run "mv #{release_path}/config/initializers/compta.rb #{shared_path}/config/initializers"
    end
    if remote_file_exist? "#{shared_path}/config/initializers/site.rb"
      run "rm #{release_path}/config/initializers/site.rb"
    else
      run "mv #{release_path}/config/initializers/site.rb #{shared_path}/config/initializers"
    end
    if remote_file_exist? "#{shared_path}/config/initializers/address_delivery_list.rb"
      run "rm #{release_path}/config/initializers/address_delivery_list.rb"
    end
  end
end

namespace :mod_rails do
  desc "Restart the application altering tmp/restart.txt for mod_rails."
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end

namespace :deploy do
  %w(start restart).each { |name| task name, :roles => :app do mod_rails.restart end }
end

namespace :git do
  desc "Push code to local and origin"
  task :push, :roles => :app do
    %x(git push local master)
    %x(git push origin master)
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
    delayed_job.stop
    delayed_job.start
  end
end

namespace :worker do
  desc "Start worker process"
  task :start, :roles => :app do
    # nothing to do
  end

  desc "Stop worker process"
  task :stop, :roles => :app do
    # nothing to do
  end
end
