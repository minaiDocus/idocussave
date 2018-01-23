require 'spec_helper'

describe SendToDropbox do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  before(:each) do
    @user = FactoryGirl.create :user, code: 'IDO%0001'
    @user.create_options
    @user.create_notify
    @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

    @dropbox = @user.external_file_storage.dropbox_basic
    @dropbox.access_token = 'K4z7I_InsgsAAAAAAAAAkZ76RjGf_qZVQ6y72HOjmCJ1FWGFufHC9ZGbfuqO3fQO'
    @dropbox.save
    @dropbox.enable

    pack = Pack.new
    pack.owner = @user
    pack.name = 'IDO%0001 AC 201701 all'
    pack.save

    @document = Document.new
    @document.pack           = pack
    @document.position       = 1
    @document.content        = File.open Rails.root.join('spec/support/files/2pages.pdf')
    @document.origin         = 'upload'
    @document.is_a_cover     = false
    @document.save

    @remote_file              = RemoteFile.new
    @remote_file.receiver     = @user
    @remote_file.pack         = pack
    @remote_file.service_name = 'Dropbox'
    @remote_file.remotable    = @document
    @remote_file.save
  end

  it 'delivers 1 file successfully' do
    result = VCR.use_cassette('dropbox/upload_file', preserve_exact_body_bytes: true) do
      SendToDropbox.new(@dropbox, [@remote_file]).execute
    end

    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload').
      with(headers: { 'Dropbox-Api-Arg' => { mode: { '.tag' => 'overwrite' }, path: "/IDO%0001/201701/AC/2pages.pdf" }.to_json })
    expect(WebMock).to have_requested(:any, /.*/).times(2)

    expect(result).to eq true
  end

  it 'uploads a file by chunk' do
    @document.content = File.open Rails.root.join('spec/support/files/3pages.pdf')
    @document.save

    result = VCR.use_cassette('dropbox/upload_file_by_chunk', preserve_exact_body_bytes: true) do
      SendToDropbox.new(@dropbox, [@remote_file], chunk_size: 400).execute
    end

    expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/start')
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/append_v2').
      with(headers: { 'Dropbox-Api-Arg' => { cursor: { session_id: 'AAAAAAAAAJ28INiLaMH3KA', offset: 400 } }.to_json })
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/append_v2').
      with(headers: { 'Dropbox-Api-Arg' => { cursor: { session_id: 'AAAAAAAAAJ28INiLaMH3KA', offset: 800 } }.to_json })
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/finish').
      with(headers: {
        'Dropbox-Api-Arg' => {
          cursor: { session_id: 'AAAAAAAAAJ28INiLaMH3KA', offset: 1200 },
          commit: { mode: 'overwrite', path: '/IDO%0001/201701/AC/3pages.pdf' }
        }.to_json })
    expect(WebMock).to have_requested(:any, /.*/).times(5)

    expect(result).to eq true
  end

  # NOTE: needs a better implementation of error
  it 'uploads a file by chunk and retry on error' do
    @document.content = File.open Rails.root.join('spec/support/files/3pages.pdf')
    @document.save

    is_error_raised = false
    allow_any_instance_of(DropboxApi::Client).to receive(:upload_session_append_v2).and_wrap_original do |m, *args|
      if is_error_raised
        m.call(*args)
      else
        is_error_raised = true
        raise DropboxApi::Errors::RateLimitError.new('rate limit', nil)
      end
    end

    expect_any_instance_of(SendToDropbox).to receive(:up_to_date?).and_return(false, false)

    result = VCR.use_cassette('dropbox/upload_file_by_chunk_and_retry_on_error', preserve_exact_body_bytes: true) do
      SendToDropbox.new(@dropbox, [@remote_file], chunk_size: 400).execute
    end

    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/start')
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/append_v2').
      with(headers: { 'Dropbox-Api-Arg' => { cursor: { session_id: 'AAAAAAAAAJ28INiLaMH3KA', offset: 400 } }.to_json })
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/append_v2').
      with(headers: { 'Dropbox-Api-Arg' => { cursor: { session_id: 'AAAAAAAAAJ28INiLaMH3KA', offset: 800 } }.to_json })
    expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload_session/finish').
      with(headers: { 'Dropbox-Api-Arg' => { cursor: { session_id: 'AAAAAAAAAJ28INiLaMH3KA', offset: 1200 },
                                             commit: { mode: 'overwrite', path: '/IDO%0001/201701/AC/3pages.pdf' }
                                           }.to_json })
    expect(WebMock).to have_requested(:any, /.*/).times(4)

    expect(result).to eq true
  end

  context 'a file has already been uploaded' do
    it 'does not update an existing file' do
      result = VCR.use_cassette('dropbox/does_not_update_an_existing_file', preserve_exact_body_bytes: true) do
        SendToDropbox.new(@dropbox, [@remote_file]).execute
      end

      expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
      expect(WebMock).to have_requested(:any, /.*/).times(1)

      expect(result).to eq true
    end

    it 'updates an existing file' do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, '2pages.pdf')
        FileUtils.cp Rails.root.join('spec/support/files/3pages.pdf'), file_path

        @document.content = File.open file_path
        @document.save

        result = VCR.use_cassette('dropbox/update_a_file', preserve_exact_body_bytes: true) do
          SendToDropbox.new(@dropbox, [@remote_file]).execute
        end

        expect(WebMock).to have_requested(:post, 'https://api.dropboxapi.com/2/files/list_folder')
        expect(WebMock).to have_requested(:post, 'https://content.dropboxapi.com/2/files/upload').
          with(headers: { 'Dropbox-Api-Arg' => { mode: { '.tag' => 'overwrite' }, path: "/IDO%0001/201701/AC/2pages.pdf" }.to_json })
        expect(WebMock).to have_requested(:any, /.*/).times(2)

        expect(result).to eq true
      end
    end
  end

  it 'manages insufficient space error' do
    allow_any_instance_of(SendToDropbox).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(DropboxApi::Client).to receive(:upload).and_raise(DropboxApi::Errors::UploadWriteFailedError.new('path/insufficient_space', nil))

    expect(@dropbox).to be_used

    result = SendToDropbox.new(@dropbox, [@remote_file]).execute

    expect(result).to eq false
    expect(@dropbox).to_not be_used
    expect(@user.notifications.size).to eq 1
  end

  it 'manages invalid token error' do
    allow_any_instance_of(SendToDropbox).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(DropboxApi::Client).to receive(:upload).and_raise(DropboxApi::Errors::HttpError.new("HTTP 401: {\"error_summary\": \"invalid_access_token/..\", \"error\": {\".tag\": \"invalid_access_token\"}}"))

    expect(@dropbox).to be_configured

    result = SendToDropbox.new(@dropbox, [@remote_file]).execute

    expect(result).to eq false
    expect(@dropbox).to_not be_configured
    expect(@user.notifications.size).to eq 1
  end
end
