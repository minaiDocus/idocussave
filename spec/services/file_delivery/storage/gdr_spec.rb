require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe "SendToGdr" do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  before(:each) do
    allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')
    allow(FileUtils).to receive(:delay_for).and_return(FileUtils)
    allow(FileUtils).to receive(:remove_entry).and_return(true)

    @leader = FactoryBot.create :user, code: 'IDO%LEAD'
    @organization = create :organization, code: 'IDO'
    @member = Member.create(user: @leader, organization: @organization, role: 'admin', code: 'IDO%LEADX')
    @organization.admin_members << @leader.memberships.first
    @leader.update(organization: @organization)
    @user = FactoryBot.create :user, code: 'IDO%001'

    @external_file_storage = ExternalFileStorage.new
    @external_file_storage.path = "iDocus/:code/:year:month/:account_book/"
    @external_file_storage.used = 4
    @external_file_storage.authorized = 30
    @external_file_storage.user = @user
    @external_file_storage.save


    @storage = @external_file_storage.google_doc
    @storage.path = "iDocus/:code/:year:month/:account_book/"
    @storage.access_token = "ya29.a0AfH6SMC_d51dXI7LeptOoHzwysWSGVxNorAeIO8Qe5wzfHbmD6LC2fiZE_0f8zS4BPtdZyoa4y28mU6m31mleT0BMx7MWTsZCibsYn4DClTmRtxddKa1NHgO1J5LpXCpiaqoldEx7_hxRqUxOo6veeRUSVfe"
    @storage.refresh_token = "1//03-vp-oHAzk5yCgYIARAAGAMSNwF-L9Irwdi6acEBfKf4xZEOUmP6qC9r5PlCrDWP12CaQm_YI1CmQqXfRtraplNV5cHlmwMEIdE"
    @storage.access_token_expires_at = "Fri, 16 Oct 2020 13:44:46 +0300".to_datetime
    @storage.is_configured = true
    @storage.save

    @pack              = Pack.new
    @pack.owner        = @user
    @pack.organization = @organization
    @pack.name         = 'IDO%001 AC 202010 all'
    @pack.save

    @document              = Pack::Piece.new
    @document.pack         = @pack
    @document.user         = @user
    @document.organization = @organization
    @document.name         = "IDO%001 AC 202010 001"
    @document.origin       = 'upload'
    @document.is_a_cover   = false
    @document.cloud_content_object.attach(File.open(Rails.root.join('spec/support/files/2pages.pdf')), '2pages.pdf') if @document.save

    @remote_file              = RemoteFile.new
    @remote_file.receiver     = @user
    @remote_file.pack         = @pack
    @remote_file.service_name = RemoteFile::GOOGLE_DRIVE
    @remote_file.remotable    = @document
    @remote_file.save
  end

  it 'sends a file successfully', :send_files do
    FileDelivery::DeliverFile.to "gdr"

    expect(@remote_file.reload.state).to eq 'synced'
  end
end
