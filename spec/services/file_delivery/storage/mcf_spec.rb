require 'spec_helper'
Sidekiq::Testing.inline! #execute jobs immediatly

describe FileDelivery::Storage::Mcf do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  before(:each) do
    allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')
    allow(FileUtils).to receive(:delay_for).and_return(FileUtils)
    allow(FileUtils).to receive(:remove_dir).and_return(true)

    customer = FactoryBot.create :user, code: 'IDO%DOC1'
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
    @pack.name = 'IDO%0001 AC 201804 all'
    @pack.save

    @document = FactoryBot.create :piece, name: 'IDO%0001 AC 201804 001', position: 1, pack: @pack, organization: @organization, user: customer
    @document.cloud_content_object.attach(File.open(Rails.root.join('spec/support/files/2pages.pdf')), '2pages.pdf') if @document.save

    @remote_file              = RemoteFile.new
    @remote_file.receiver     = @organization
    @remote_file.pack         = @pack
    @remote_file.service_name = RemoteFile::MY_COMPANY_FILES
    @remote_file.remotable    = @document
    @remote_file.save
  end

  it 'sends a file successfully', :send_files do
    result = VCR.use_cassette('mcf/upload_file') do
      FileDelivery::DeliverFile.to "mcf"
    end

    expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
    expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

    expect(@remote_file.reload.state).to eq 'synced'
  end

  it 'cancels remote files if mcf storage is not present', :failed_sending do
    @user.update(mcf_storage: "")

    result = VCR.use_cassette('mcf/upload_file') do
      FileDelivery::DeliverFile.to "mcf"
    end

    expect(@remote_file.reload.state).to eq 'cancelled'
  end

  context 'a file has already been uploaded', :upload_existing_file do
    it 'does not update an existing file', :test do
      allow_any_instance_of(Storage::Metafile).to receive(:fingerprint).and_return('97f90eac0d07fe5ade8f60a0fa54cdfc')

      result = VCR.use_cassette('mcf/does_not_update_an_existing_file') do
        FileDelivery::DeliverFile.to "mcf"
      end

      expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
      expect(WebMock).to have_not_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

      expect(@remote_file.reload.state).to eq 'synced'
    end

    it 'updates a modified existing file' do
      CustomUtils.mktmpdir do |dir|
        file_path = File.join(dir, '2pages.pdf')
        FileUtils.cp Rails.root.join('spec/support/files/3pages.pdf'), file_path

        @document.cloud_content_object.attach(File.open(file_path), 'test.pdf')
        @document.save

        result = VCR.use_cassette('mcf/update_a_file') do
          FileDelivery::DeliverFile.to "mcf"
        end

        expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/VerifyFile')
        expect(WebMock).to have_requested(:post, 'https://uploadservice.mycompanyfiles.fr/api/idocus/Upload')

        expect(@remote_file.reload.state).to eq 'synced'
      end
    end
  end

  it 'manages insufficient space error', :handling_space_error do
    message = "{\"CodeError\":507,\"Success\":false,\"StorageLimitReached\":true}"
    allow_any_instance_of(FileDelivery::Storage::Mcf).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(McfLib::Api::Mcf::Client).to receive(:upload).and_raise(McfLib::Api::Mcf::Errors::Unknown.new(message))

    expect(@mcf.is_delivery_activated).to eq true

    result = FileDelivery::Storage::Mcf.new(@mcf, [@remote_file]).execute

    expect(result).to eq false
    expect(@mcf.is_delivery_activated).to eq false
    expect(@leader.notifications.size).to eq 1
  end

  it 'manages invalid token error', :handling_invalid_token do
    allow_any_instance_of(FileDelivery::Storage::Mcf).to receive(:up_to_date?).and_return(false)
    allow_any_instance_of(McfLib::Api::Mcf::Client).to receive(:upload).and_raise(McfLib::Api::Mcf::Errors::Unauthorized)

    expect(@mcf).to be_configured

    result = FileDelivery::Storage::Mcf.new(@mcf, [@remote_file], max_retries: 1).execute

    expect(result).to eq false
    expect(@mcf).to_not be_configured
    expect(@leader.notifications.size).to eq 1
  end

  # TEMP: Not used for now
  # it 'cancels the remote sending if no receiver' do
  #   @remote_file.update(organization_id: nil, user_id: nil, group_id: nil)
  #   FileDelivery::DeliverFile.to "mcf"

  #   expect(@remote_file.reload.state).to eq 'cancelled'
  # end
end
