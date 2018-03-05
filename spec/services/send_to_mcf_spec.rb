require 'spec_helper'

describe SendToMcf do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  before(:each) do
    @leader = FactoryGirl.create :user, code: 'IDO%LEAD'
    @organization = create :organization, code: 'IDO', leader: @leader
    @leader.update(organization: @organization)
    @mcf = McfSettings.create(
      organization: @organization,
      access_token: '64b01bda571f47aea8814cb7a29a7dc356310755ce01404f',
      access_token_expires_at: 1.year.from_now
    )
    user = FactoryGirl.create :user, code: 'IDO%0001', mcf_storage: 'John Doe'

    pack = Pack.new
    pack.owner = user
    pack.name = 'IDO%0001 AC 201801 all'
    pack.save

    @document = Document.new
    @document.pack       = pack
    @document.position   = 1
    @document.content    = File.open Rails.root.join('spec/support/files/2pages.pdf')
    @document.origin     = 'upload'
    @document.is_a_cover = false
    @document.save

    @remote_file              = RemoteFile.new
    @remote_file.receiver     = @organization
    @remote_file.pack         = pack
    @remote_file.service_name = RemoteFile::MY_COMPANY_FILES
    @remote_file.remotable    = @document
    @remote_file.save
  end

  it 'sends a file successfully', :send_files do
    result = VCR.use_cassette('mcf/upload_file') do
      SendToMcf.new(@mcf, [@remote_file]).execute
    end

    expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
    expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')
    expect(WebMock).to have_requested(:any, /.*/).times(2)

    expect(result).to eq true
    expect(@remote_file.state).to eq 'synced'
  end

  context 'a file has already been uploaded', :upload_existing_file do
    it 'does not update an existing file' do
      result = VCR.use_cassette('mcf/does_not_update_an_existing_file') do
        SendToMcf.new(@mcf, [@remote_file]).execute
      end

      expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
      expect(WebMock).to have_requested(:any, /.*/).times(1)

      expect(result).to eq true
    end

    it 'updates an existing file' do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, '2pages.pdf')
        FileUtils.cp Rails.root.join('spec/support/files/3pages.pdf'), file_path

        @document.content = File.open file_path
        @document.save

        result = VCR.use_cassette('mcf/update_a_file', preserve_exact_body_bytes: true) do
          SendToMcf.new(@mcf, [@remote_file]).execute
        end

        expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
        expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')
        expect(WebMock).to have_requested(:any, /.*/).times(2)

        expect(result).to eq true
      end
    end
  end

  it 'manages insufficient space error', :handling_space_error do
    message = "{\"CodeError\":507,\"Success\":false,\"StorageLimitReached\":true}"
    allow_any_instance_of(SendToMcf).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(McfApi::Client).to receive(:upload).and_raise(McfApi::Errors::Unknown.new(message))

    expect(@mcf.is_delivery_activated).to eq true

    result = SendToMcf.new(@mcf, [@remote_file]).execute

    expect(result).to eq false
    expect(@mcf.is_delivery_activated).to eq false
    expect(@leader.notifications.size).to eq 1
  end

  it 'manages invalid token error', :handling_invalid_token do
    allow_any_instance_of(SendToMcf).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(McfApi::Client).to receive(:upload).and_raise(McfApi::Errors::Unauthorized)

    expect(@mcf).to be_configured

    result = SendToMcf.new(@mcf, [@remote_file], max_retries: 1).execute

    expect(result).to eq false
    expect(@mcf).to_not be_configured
    expect(@leader.notifications.size).to eq 1
  end
end
