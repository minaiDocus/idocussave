set :application, "idocus"

set :repo_url, "git@github.com:dbarbarossa/idocusave.git"

set :branch, "master-v3"

set :rvm_ruby_version, '2.3.1'

set :linked_dirs, fetch(:linked_dirs, []).push('log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'vendor/bundle', 'public/system', 'data')

set :linked_files, fetch(:linked_files, []).push('config/database.yml', 'config/secrets.yml', 'config/dematbox.yml', 'config/fiduceo.yml',
                                                 'config/box.yml', 'config/dematbox_service_api.yml', 'config/knowings.yml', 'config/emailed_document.yml',
                                                 'config/ibiza.yml', 'config/slimpay.yml', 'config/dropbox.yml', 'config/google_drive.yml',
                                                 'config/pdftk.yml', 'config/smtp.yml', 'config/ppp_ftp.yml')

namespace :deploy do
  after :updated, :link_production_data do
    on roles(:all) do
      execute "ln -s /data/idocus/production_data/files #{release_path}/files"
    end
  end


  after :finished, :restart_passenger do
    on roles(:all) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end
