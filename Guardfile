# frozen_string_literal: true

guard 'rspec', cmd: 'bin/rspec' do
  watch('spec/spec_helper.rb')                       { 'spec' }
  watch('app/controllers/application_controller.rb') { 'spec/controllers' }
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})                          { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch(%r{^app/modules/(.+)\.rb$})                  { |m| "app/modules/#{m[1]}_spec.rb" }
  watch(%r{^app/(.+)\.rb$})                          { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^app/(.*)(\.erb|\.haml)$})                { |m| "spec/#{m[1]}#{m[2]}_spec.rb" }
  watch(%r{^app/controllers/(.+)_(controller)\.rb$}) { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb"] }
  watch(%r{^spec/support/(.+)\.rb$})                 { 'spec' }

  watch(%r{app/modules/dropbox_import/.*})           { |_m| 'spec/modules/dropbox_import_spec.rb' }
  watch('app/services/send_to_storage.rb')           { |_m| ['spec/services/send_to_dropbox_spec.rb', 'spec/services/send_to_ftp_spec.rb', 'spec/services/send_to_mcf_spec.rb'] }
  watch('app/models/storage/metafile.rb')            { |_m| ['spec/services/send_to_storage_spec.rb', 'spec/services/send_to_dropbox_spec.rb', 'spec/services/send_to_ftp_spec.rb'] }
  watch('app/services/ftp_client.rb')                { |_m| ['spec/services/send_to_ftp_spec.rb', 'spec/services/ftp_import_spec.rb'] }
  watch(%r{app/models/(user|account_sharing).rb})    { |_m| 'spec/integration/share_accounts_spec.rb' }
end

guard 'livereload' do
  watch(%r{app/views/.+\.(erb|haml|slim)$})
  watch(%r{app/helpers/.+\.rb})
  watch(%r{public/.+\.(css|js|html)})
  watch(%r{config/locales/.+\.yml})
  # Rails Assets Pipeline
  watch(%r{(app|vendor)(/assets/\w+/(.+\.(css|js|html|png|jpg))).*}) { |m| "/assets/#{m[3]}" }
end
