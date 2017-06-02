set :application, 'idocus'

set :repo_url, 'git@github.com:dbarbarossa/idocusave.git'

set :branch, 'master'

set :rvm_ruby_version, '2.3.1'

set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'tmp/barcode',
  'vendor/bundle',
  'public/system',
  'data'
)

set :linked_files, fetch(:linked_files, []).push(
  'config/database.yml',
  'config/secrets.yml',
  'config/dematbox.yml',
  'config/budgea.yml',
  'config/fiduceo.yml',
  'config/dematbox_service_api.yml',
  'config/knowings.yml',
  'config/emailed_document.yml',
  'config/ibiza.yml',
  'config/slimpay.yml',
  'config/pdftk.yml',
  'config/smtp.yml',
  'config/ftp_delivery.yml'
)

server 'my.idocus.com', user: 'idocus', roles: %w{app db web}

namespace :deploy do
  after :finished, :restart_passenger do
    on roles(:all) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end

namespace :utils do
  desc 'Upload uncommited modified files'
  task :upload_modified do
    on roles(:all) do
      data = %x(git ls-files --other --exclude-standard -m | uniq)
      data.split(/\n/).each do |file_path|
        upload! file_path, release_path.join(file_path)
      end
    end
  end

  desc 'Upload modified files in last commit'
  task :upload_last_commit do
    on roles(:all) do
      data = %x(git log --name-only --pretty=oneline --full-index HEAD^..HEAD | grep -vE '^[0-9a-f]{40} ' | sort | uniq)
      data.split(/\n/).each do |file_path|
        upload! file_path, release_path.join(file_path)
      end
    end
  end
end
