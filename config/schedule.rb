set :job_template, "/bin/bash -c '. /home/grevalis/.rvm/environments/ruby-1.9.3-p551 && :job'"

options = { output: { error: 'log/cron.log', standard: 'log/cron.log' } }

every :day do
  rake 'maintenance:notification:scans_not_delivered', options
end

every :day, at: '04:30' do
  rake 'prepa_compta:update_accounting_plan', options
end

every :day, at: '06:00' do
  rake 'fiduceo:transaction:initiate', options
end

every :day, at: '07:00' do
  rake 'fiduceo:notify_password_renewal', options
end

every :day, at: '08:00' do
  rake 'fiduceo:provider:notify_processed_wishes', options
end

every :day, at: '08:01' do
  rake 'maintenance:notification:document_updated', options
end

every :day, at: '08:02' do
  rake 'maintenance:notification:document_pending', options
end

every :day, at: '9:30' do
  rake 'fiduceo:notify_insane_retrievers', options
end

every :month, at: '02:00' do
  rake 'maintenance:invoice:generate', options
end

every :month, at: '02:02' do
  rake 'maintenance:reporting:init', options
end
