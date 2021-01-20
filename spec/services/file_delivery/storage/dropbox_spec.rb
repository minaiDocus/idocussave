require 'spec_helper'

describe FileDelivery::Storage::Dropbox do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) do
    Timecop.return
    DatabaseCleaner.clean_with(:truncation)
  end

  before(:each) do
    Timecop.freeze(Time.local(2020,10,1))

    organization = create :organization, code: 'IDO'

    @user = FactoryBot.create :user, code: 'IDO%001'
    @user.organization = organization
    @user.create_options
    @user.create_notify
    @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)
    @user.save

    @dropbox = @user.external_file_storage.dropbox_basic
    @dropbox.access_token = 'd_8hw4XA240AAAAAAAAAAbdOcCNXL3qwaOp05judYxFkgJBjoRxIwBlDVCbOW3m2'
    @dropbox.save
    @dropbox.enable

    pack = Pack.new
    pack.owner = @user
    pack.organization = organization
    pack.name = 'IDO%001 AC 202010 all'
    pack.save

    @document = FactoryBot.create :piece, pack: pack, organization: organization, user: @user, name: 'IDO%001 AC 202010 001'
    @document.cloud_content_object.attach(File.open(Rails.root.join('spec/support/files/2pages.pdf')), '2pages.pdf') if @document.save

    @remote_file              = RemoteFile.new
    @remote_file.receiver     = @user
    @remote_file.pack         = pack
    @remote_file.service_name = 'Dropbox'
    @remote_file.remotable    = @document
    @remote_file.save
  end

  it 'delivers 1 file successfully' do
    result = VCR.use_cassette('dropbox/upload_file', preserve_exact_body_bytes: true) do
      FileDelivery::Storage::Dropbox.new(@dropbox, [@remote_file]).execute
    end

    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload')
    expect(WebMock).to have_requested(:any, /dropboxapi/).times(2)

    expect(result).to eq true
    expect(@remote_file.reload.state).to eq 'synced'
  end

  context 'a file has already been uploaded' do
    it 'does not update an existing file' do
      result = VCR.use_cassette('dropbox/does_not_update_an_existing_file', preserve_exact_body_bytes: true) do
        FileDelivery::Storage::Dropbox.new(@dropbox, [@remote_file]).execute
      end

      expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
      expect(WebMock).to have_requested(:any, /dropboxapi/).times(1)

      expect(result).to eq true
      expect(@remote_file.reload.state).to eq 'synced'
    end

    it 'updates an existing file' do
      CustomUtils.mktmpdir(nil, false) do |dir|
        file_path = File.join(dir, '2pages.pdf')
        FileUtils.cp Rails.root.join('spec/support/files/3pages.pdf'), file_path

        @document.cloud_content_object.attach(File.open(file_path), '3pages.pdf')
        @document.save

        result = VCR.use_cassette('dropbox/update_a_file', preserve_exact_body_bytes: true) do
          FileDelivery::Storage::Dropbox.new(@dropbox, [@remote_file]).execute
        end

        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
        expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload')
        expect(WebMock).to have_requested(:any, /dropboxapi/).times(2)

        expect(result).to eq true
        expect(@remote_file.reload.state).to eq 'synced'
      end
    end
  end

  it 'manages insufficient space error' do
    allow_any_instance_of(FileDelivery::Storage::Dropbox).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(DropboxApi::Client).to receive(:upload).and_raise(DropboxApi::Errors::UploadWriteFailedError.new('path/insufficient_space', nil))

    expect(@dropbox).to be_used

    result = FileDelivery::Storage::Dropbox.new(@dropbox, [@remote_file]).execute

    expect(result).to eq false
    expect(@dropbox).to_not be_used
    expect(@remote_file.reload.state).to eq 'not_synced'
    expect(@user.notifications.size).to eq 1
  end

  it 'manages invalid token error' do
    allow_any_instance_of(FileDelivery::Storage::Dropbox).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(DropboxApi::Client).to receive(:upload).and_raise(DropboxApi::Errors::HttpError.new("HTTP 401: {\"error_summary\": \"invalid_access_token/..\", \"error\": {\".tag\": \"invalid_access_token\"}}"))

    expect(@dropbox).to be_configured

    result = FileDelivery::Storage::Dropbox.new(@dropbox, [@remote_file]).execute

    expect(result).to eq false
    expect(@dropbox).to_not be_configured
    expect(@remote_file.reload.state).to eq 'not_synced'
    expect(@user.notifications.size).to eq 1
  end
end
