# Basic test with FakeFTP server, multi-thread does not work with it

require 'spec_helper'
require 'ftpd'

describe 'SendToFTP' do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  class Driver
    def initialize(temp_dir, is_authenticatable=true)
      @temp_dir = temp_dir
      @is_authenticatable = is_authenticatable
    end

    def authenticate(user, password)
      @is_authenticatable
    end

    def file_system(user)
      Ftpd::DiskFileSystem.new @temp_dir
    end
  end

  describe '#execute' do
    before(:all) do
      Timecop.freeze(Time.local(2020,10,15))
    end

    after(:all) do
      Timecop.return
    end

    describe 'given 3 remote files to deliver for a user', :delivery_to_user do
      before(:each) do
        allow(Settings).to receive(:first).and_return(FakeObject.new)
        allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')
        allow_any_instance_of(FakeObject).to receive(:notify_errors_to).and_return('mina@idocus.com')

        organization = FactoryBot.create :organization, code: 'IDO'

        @user = FactoryBot.create :user, code: 'IDO%001'
        @user.organization = organization
        @user.create_options
        @user.create_notify
        @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

        @ftp = @user.external_file_storage.ftp
        @ftp.host = 'ftp://localhost'
        @ftp.path = 'files/iDocus/:code/:year:month/:account_book'
        @ftp.save
        @ftp.enable

        @pack              = Pack.new
        @pack.organization = organization
        @pack.owner        = @user
        @pack.name         = 'IDO%001 AC 202010 all'
        @pack.save

        counter = 0

        @remote_files = ['2pages.pdf', '3pages.pdf', '5pages.pdf'].map do |file_name|
          document              = Pack::Piece.new
          document.name         = "IDO%001 AC 202010 00#{counter += 1}"
          document.pack         = @pack
          document.user         = @user
          document.organization = organization
          document.position     = 1
          document.origin       = 'upload'
          document.is_a_cover   = false
          document.cloud_content_object.attach(File.open(Rails.root.join("spec/support/files/#{file_name}")), file_name) if document.save

          remote_file              = RemoteFile.new
          remote_file.receiver     = @user
          remote_file.pack         = @pack
          remote_file.service_name = 'FTP'
          remote_file.remotable    = document
          remote_file.save
          remote_file
        end
      end

      it 'fails to authenticate' do
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir, false
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileDelivery::Storage::Ftp.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          expect(@ftp.configured?).to eq false
          expect(@user.notifications.size).to eq 1
          expect(@user.notifications.first.notice_type).to eq 'ftp_auth_failure'

          server.stop
        end
      end

      it 'sends 3 files successfully' do
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileDelivery::Storage::Ftp.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          files = Dir.glob("#{dir}/files/iDocus/IDO%001/202010/AC/*.pdf").sort.map do |path|
            File.basename path
          end

          expect(files).to eq ["IDO%001_AC_202010_001.pdf", "IDO%001_AC_202010_002.pdf", "IDO%001_AC_202010_003.pdf"]

          server.stop
        end
      end
    end

    describe 'given 3 remote files to deliver for an organization', :delivery_to_organization do
      before(:each) do
        allow(Settings).to receive(:first).and_return(FakeObject.new)
        allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')
        allow_any_instance_of(FakeObject).to receive(:notify_errors_to).and_return('mina@idocus.com')

        @organization = FactoryBot.create :organization, code: 'IDO'
        @user = FactoryBot.create :user, code: 'IDO%001'
        @user.organization = @organization
        @user.save

        @user.create_options
        @user.create_notify

        @ftp = @organization.build_ftp
        @ftp.host      = 'ftp://localhost'
        @ftp.path      = 'OUTPUT/:code/:year:month/:account_book'
        @ftp.root_path = 'files/iDocus'
        @ftp.save
        @ftp.enable

        @pack              = Pack.new
        @pack.owner        = @user
        @pack.organization = @organization
        @pack.name         = 'IDO%001 AC 202010 all'
        @pack.save

        counter = 0

        @remote_files = ['2pages.pdf', '3pages.pdf', '5pages.pdf'].map do |file_name|
          document              = Pack::Piece.new
          document.name         = "IDO%001 AC 202010 00#{counter += 1}"
          document.pack         = @pack
          document.user         = @user
          document.organization = @organization
          document.position     = 1
          document.origin       = 'upload'
          document.is_a_cover   = false
          document.cloud_content_object.attach(File.open(Rails.root.join("spec/support/files/#{file_name}")), file_name) if document.save


          remote_file              = RemoteFile.new
          remote_file.receiver     = @organization
          remote_file.pack         = @pack
          remote_file.service_name = 'FTP'
          remote_file.remotable    = document
          remote_file.save
          remote_file
        end
      end

      it 'sends 3 files successfully' do
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileDelivery::Storage::Ftp.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          files = Dir.glob(File.join(dir, @ftp.root_path, "OUTPUT/IDO%001/202010/AC/*.pdf")).sort.map do |path|
            File.basename path
          end

          expect(files).to eq ["IDO%001_AC_202010_001.pdf", "IDO%001_AC_202010_002.pdf", "IDO%001_AC_202010_003.pdf"]

          server.stop
        end
      end
    end
  end
end
