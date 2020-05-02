set :application, 'idocus'

set :conditionally_migrate, true

set :linked_dirs, fetch(:linked_dirs, []).push(
  'log',
  'tmp/pids',
  'tmp/cache',
  'tmp/sockets',
  'tmp/barcode',
  'vendor/bundle',
  'public/system',
  'files'
  'data',
  'keys'
)

set :linked_files, fetch(:linked_files, []).push(
  'config/bearer.yml',
  'config/database.yml',
  'config/secrets.yml',
  'config/dematbox.yml',
  'config/budgea.yml',
  'config/dematbox_service_api.yml',
  'config/knowings.yml',
  'config/emailed_document.yml',
  'config/ibiza.yml',
  'config/slimpay.yml',
  'config/pdftk.yml',
  'config/smtp.yml',
  'config/ftp_delivery.yml',
  'config/storage.yml',
  'config/elastic_apm.yml',
  'config/supplier_recognition.yml'
)

set :slack_url, 'https://hooks.slack.com/services/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'


namespace :deploy do
  after :finished, :restart_passenger do
    on roles(:web) do
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end
end
