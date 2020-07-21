require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe SendToMcf do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  before(:each) do
    allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')
    allow(FileUtils).to receive(:delay_for).and_return(FileUtils)
    allow(FileUtils).to receive(:remove_dir).and_return(true)

    @leader = FactoryBot.create :user, code: 'IDO%LEAD'
    @organization = create :organization, code: 'IDO'
    @member = Member.create(user: @leader, organization: @organization, role: 'admin', code: 'IDO%LEADX')
    @organization.admin_members << @leader.memberships.first
    @leader.update(organization: @organization)
    @mcf = McfSettings.create(
      organization: @organization,
      access_token: '64b01bda571f47aea8814cb7a29a7dc356310755ce01404f',
      access_token_expires_at: 1.year.from_now
    )
    @user = FactoryBot.create :user, code: 'IDO%0001', mcf_storage: 'John Doe'

    @pack = Pack.new
    @pack.owner = @user
    @pack.organization = @organization
    @pack.name = 'IDO%0001 AC 202008 all'
    @pack.save

    @document = Document.new
    @document.pack       = @pack
    @document.position   = 1
    @document.origin     = 'upload'
    @document.is_a_cover = false
    @document.cloud_content_object.attach(File.open(Rails.root.join('spec/support/files/2pages.pdf')), '2pages.pdf') if @document.save

    @remote_file              = RemoteFile.new
    @remote_file.receiver     = @organization
    @remote_file.pack         = @pack
    @remote_file.service_name = RemoteFile::MY_COMPANY_FILES
    @remote_file.remotable    = @document
    @remote_file.save
  end

  #WebMock.disable_net_connect(allow: ['https://uploadservice.mycompanyfiles.fr/api/idocus/Upload'])

  it 'sends a file successfully', :send_files do
    WebMock.allow_net_connect!

    result = VCR.use_cassette('mcf/upload_file') do
      DeliverFile.to "mcf"
    end

    file_path = Rails.root.join('spec/support/files/2pages.pdf')
    remote_path = 'John Doe/TEST/2pages.pdf'

    force = true

    remote_storage = remote_path.split("/")[0]
    remote_path.slice!("#{remote_storage}/")

      data = {
        :accessToken => @access_token,
        :attributeName => "Storage",
        :attributeValue => remote_storage,
        :sendMail => 'false',
        :force => force.to_s,
        :pathFile => remote_path,
        :file => Faraday::FilePart.new(File.open(file_path), 'application/pdf', File.basename(file_path))
      }

    #request = stub_request(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

    client = McfApi::Client.new('64b01bda571f47aea8814cb7a29a7dc356310755ce01404f')

    upload_result = VCR.use_cassette('mcf/upload') do
      client.upload(file_path, 'John Doe/TEST/2pages.pdf')
    end

    #expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')

    expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

    #WebMock::Config.instance.query_values_notation = :flat_array

    # a_request(:post, "https://uploadservice.mycompanyfiles.fr/api/idocus/Upload").should have_been_made.times(1)
    #expect(WebMock).to have_requested(:post, "https://uploadservice.mycompanyfiles.fr/api/idocus/Upload").with(body: data.to_query, headers: header)


    #expect(WebMock).to have_requested(:post, "https://uploadservice.mycompanyfiles.fr/api/idocus/Upload").with(body: data)
    # expect(WebMock).to(have_requested(
    #   :post,
    #   "https://uploadservice.mycompanyfiles.fr/api/idocus/Upload"
    # ).with(body: data, headers: {'Accept' => 'application/json', 'Content-Type' => 'application/json'})) do |request|
    #   raise "FAIL!"
    # end

    # expect(a_request(:post, "https://uploadservice.mycompanyfiles.fr/api/idocus/Upload").
    # with(body: data,
    #   headers: {'Accept' => 'application/json', 'Content-Type' => 'application/json'})).to have_been_made

    #expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')


    expect(@remote_file.reload.state).to eq 'synced'
  end

  it 'cancels remote files if mcf storage is not present', :failed_sending do
    @user.update(mcf_storage: "")

    result = VCR.use_cassette('mcf/upload_file') do
      DeliverFile.to "mcf"
    end

    expect(@remote_file.reload.state).to eq 'cancelled'
  end

  context 'a file has already been uploaded', :upload_existing_file do
    it 'does not update an existing file' do
      allow_any_instance_of(Storage::Metafile).to receive(:fingerprint).and_return('97f90eac0d07fe5ade8f60a0fa54cdfc')

      result = VCR.use_cassette('mcf/does_not_update_an_existing_file') do
        DeliverFile.to "mcf"
      end

      expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
      expect(WebMock).to have_not_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

      expect(@remote_file.reload.state).to eq 'synced'
    end

    it 'updates a modified existing file' do
      Dir.mktmpdir do |dir|
        file_path = File.join(dir, '2pages.pdf')
        FileUtils.cp Rails.root.join('spec/support/files/3pages.pdf'), file_path

        @document.cloud_content_object.attach(File.open(file_path), 'test.pdf')
        @document.save

        result = VCR.use_cassette('mcf/update_a_file') do
          DeliverFile.to "mcf"
        end

        expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
        expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

        expect(@remote_file.reload.state).to eq 'synced'
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

  # TEMP: Not used for now
  # it 'cancels the remote sending if no receiver' do
  #   @remote_file.update(organization_id: nil, user_id: nil, group_id: nil)
  #   DeliverFile.to "mcf"

  #   expect(@remote_file.reload.state).to eq 'cancelled'
  # end
end
