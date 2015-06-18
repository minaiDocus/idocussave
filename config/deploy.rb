# notify deploy to airbrake
require 'airbrake/capistrano'

# automatically run bundle install
require 'bundler/capistrano'

default_run_options[:pty] = true
#ssh_options[:forward_agent] = true

set :runner, "rails"
set :normalize_asset_timestamps, false
set :user, "grevalis"
set :use_sudo, false
set :rails_env, "production"

set :application, "idocus"

set :keep_releases, 5

set :repository, "git@github.com:dbarbarossa/idocusave.git"
set :scm, "git"
set :branch, "master"
set :deploy_via, :remote_cache
set :repository_cache, "git_cache"
set :copy_exclude, [".svn", ".DS_Store", ".git"]

role :app, "grevalis.alwaysdata.net"

set :stages, %w(production staging sandbox)
set :default_stage, "production"
require 'capistrano/ext/multistage'

before "deploy", "manager:stop", "delayed_job:stop", "deploy:setup", "shared:mkdir"
before "deploy:update", "git:push"
after "deploy:finalize_update", "shared:config"
before "deploy:create_symlink", "shared:create_symlink"
after "deploy", "deploy:cleanup", "manager:start", "delayed_job:start"

namespace :shared do
  desc "Create symlink"
  task :create_symlink do
    command = []
    command << "ln -nfs #{shared_path}/config/secrets.yml #{release_path}/config/secrets.yml"
    command << "ln -nfs #{shared_path}/config/mongoid.yml #{release_path}/config/mongoid.yml"
    command << "ln -nfs #{shared_path}/config/dematbox.yml #{release_path}/config/dematbox.yml"
    command << "ln -nfs #{shared_path}/config/fiduceo.yml #{release_path}/config/fiduceo.yml"
    command << "ln -nfs #{shared_path}/config/box.yml #{release_path}/config/box.yml"
    command << "ln -nfs #{shared_path}/config/dematbox_service_api.yml #{release_path}/config/dematbox_service_api.yml"
    command << "ln -nfs #{shared_path}/config/knowings.yml #{release_path}/config/knowings.yml"
    command << "ln -nfs #{shared_path}/config/emailed_document.yml #{release_path}/config/emailed_document.yml"
    command << "ln -nfs #{shared_path}/config/ibiza.yml #{release_path}/config/ibiza.yml"
    command << "ln -nfs #{shared_path}/config/slimpay.yml #{release_path}/config/slimpay.yml"
    command << "ln -nfs #{shared_path}/config/google_drive.yml #{release_path}/config/google_drive.yml"
    command << "ln -nfs #{shared_path}/config/initializers/fix_ssl.rb #{release_path}/config/initializers/fix_ssl.rb"
    command << "ln -nfs #{shared_path}/public/system #{release_path}/public/system"
    command << "ln -s #{shared_path}/data #{release_path}/data"
    command << "ln -s #{shared_path}/files #{release_path}/files"
    run command.join('; ')
  end

  desc "Create necessary directories"
  task :mkdir do
    command = []
    command << "mkdir -p #{shared_path}/config/initializers"
    command << "mkdir -p #{shared_path}/public/system/#{rails_env}"
    command << "mkdir -p #{release_path}/tmp/barcode"
    command << "mkdir -p #{shared_path}/data/compta/mapping"
    command << "mkdir -p #{shared_path}/data/compta/abbyy/output"
    command << "mkdir -p #{shared_path}/data/compta/abbyy/processed"
    command << "mkdir -p #{shared_path}/data/compta/abbyy/errors"
    command << "mkdir -p #{shared_path}/files/#{rails_env}/kit"
    command << "mkdir -p #{shared_path}/files/#{rails_env}/archives/invoices"
    command << "mkdir -p #{shared_path}/files/#{rails_env}/compositions"
    run command.join('; ')
  end

  desc "Prepare config files"
  task :config do
    command = []

    files = [
      'secrets.yml',
      'mongoid.yml',
      'dematbox.yml',
      'fiduceo.yml',
      'box.yml',
      'dematbox_service_api.yml',
      'knowings.yml',
      'emailed_document.yml',
      'ibiza.yml',
      'slimpay.yml',
      'google_drive.yml'
    ]

    files.each do |file|
      command << "if [ ! -e #{shared_path}/config/#{file} ]"
      command << "then cp #{release_path}/config/#{file}.example #{shared_path}/config/#{file}"
      command << "fi"
    end

    run command.join('; ')
  end
end

namespace :mod_rails do
  desc "Restart the application."
  task :restart, :roles => :app do
    run "/home/grevalis/myapps/opt/passenger-5.0.8/bin/passenger-config restart-app /home/grevalis/www/idocus/#{rails_env} --ignore-app-not-running"
  end
end

namespace :deploy do
  %w(start restart).each { |name| task name, :roles => :app do mod_rails.restart end }
end

namespace :git do
  desc "Push code to local and origin"
  task :push, :roles => :app do
    %x(git push origin master)
  end
end

namespace :delayed_job do
  desc "Start delayed_job process"
  task :start, :roles => :app do
    run "cd #{release_path}; RAILS_ENV=#{rails_env} script/delayed_job start"
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

namespace :manager do
  desc "Start manager process"
  task :start, :roles => :app do
    # nothing to do
  end

  desc "Stop manager process"
  task :stop, :roles => :app do
    # nothing to do
  end
end

namespace :utils do
  desc "Upload uncommited modified files"
  task :upload_modified, :roles => :app do
    data = %x(git ls-files --other --exclude-standard -m | uniq)
    data.split(/\n/).each do |file_path|
      upload file_path, File.join(current_path, file_path)
    end
  end

  desc "Upload modified files in last commit"
  task :upload_last_commit, :roles => :app do
    data = %x(git log --name-only --pretty=oneline --full-index HEAD^..HEAD | grep -vE '^[0-9a-f]{40} ' | sort | uniq)
    data.split(/\n/).each do |file_path|
      upload file_path, File.join(current_path, file_path)
    end
  end
end
