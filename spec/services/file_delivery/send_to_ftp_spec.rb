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
      Timecop.freeze(Time.local(2017,1,15))
    end

    after(:all) do
      Timecop.return
    end

    describe 'given 3 remote files to deliver for a user', :first_test do
      before(:each) do
        allow(Settings).to receive(:first).and_return(FakeObject.new)
        allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')
        allow_any_instance_of(FakeObject).to receive(:notify_errors_to).and_return('mina@idocus.com')

        organization = FactoryBot.create :organization, code: 'IDO'

        @user = FactoryBot.create :user, code: 'IDO%0001'
        @user.organization = organization
        @user.create_options
        @user.create_notify
        @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

        @ftp = @user.external_file_storage.ftp
        @ftp.host = 'ftp://localhost'
        @ftp.path = 'files/iDocus/:code/:year:month/:account_book'
        @ftp.save
        @ftp.enable

        @pack = Pack.new
        @pack.organization = organization
        @pack.owner = @user
        @pack.name  = 'IDO%0001 AC 201701 all'
        @pack.save

        @remote_files = ['2pages.pdf', '3pages.pdf', '5pages.pdf'].map do |file_name|
          document            = Pack::Piece.new
          document.name       = "IDO%0001 AC 201701 001"
          document.pack       = @pack
          document.user       = @user
          document.position   = 1
          document.origin     = 'upload'
          document.is_a_cover = false
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
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir, false
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileDelivery::SendToFTP.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          expect(@ftp.configured?).to eq false
          expect(@user.notifications.size).to eq 1
          expect(@user.notifications.first.notice_type).to eq 'ftp_auth_failure'

          server.stop
        end
      end

      it 'sends 3 files successfully' do
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileDelivery::SendToFTP.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          files = Dir.glob("#{temp_dir}/files/iDocus/IDO%0001/201701/AC/*.pdf").sort.map do |path|
            File.basename path
          end

          expect(files).to eq ['2pages.pdf', '3pages.pdf', '5pages.pdf']

          server.stop
        end
      end
    end

    describe 'given 3 remote files to deliver for an organization' do
      before(:each) do
        allow_any_instance_of(Settings).to receive(:notify_errors_to).and_return('mina@idocus.com')

        @root_path = '/path/to/folder'
        @ftp.update root_path: @root_path

        @organization = FactoryBot.create :organization, code: 'IDO'
        @user = FactoryBot.create :user, code: 'IDO%0001'
        @user.organization = @organization
        @user.save

        @ftp = @organization.build_ftp
        @ftp.host = 'ftp://localhost'
        @ftp.path = 'OUTPUT/:code/:year:month/:account_book'
        @ftp.save
        @ftp.enable

        @pack = Pack.new
        @pack.owner = @user
        @pack.organization = @organization
        @pack.name = 'IDO%0001 AC 201701 all'
        @pack.save

        @remote_files = ['2pages.pdf', '3pages.pdf', '5pages.pdf'].map do |file_name|
          document            = Pack::Piece.new
          document.name       = "IDO%0001 AC 201701 001"
          document.pack       = @pack
          document.user       = @user
          document.position   = 1
          document.origin     = 'upload'
          document.is_a_cover = false
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
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileDelivery::SendToFTP.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          files = Dir.glob(File.join(temp_dir, @root_path, "OUTPUT/IDO%0001/201701/AC/*.pdf")).sort.map do |path|
            File.basename path
          end

          expect(files).to eq ['2pages.pdf', '3pages.pdf', '5pages.pdf']

          server.stop
        end
      end
    end
  end
end
