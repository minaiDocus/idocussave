# Basic test with FakeFTP server, multi-thread does not work with it

require 'spec_helper'
require 'ftpd'

describe SendToFTP do
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

    describe 'given 3 remote files to deliver' do
      before(:each) do
        @user = FactoryGirl.create :user, code: 'IDO%0001'
        @user.options = UserOptions.create(user_id: @user.id)
        @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

        @ftp = @user.external_file_storage.ftp
        @ftp.host = 'ftp://localhost'
        @ftp.path = 'files/iDocus/:code/:year:month/:account_book'
        @ftp.save
        @ftp.enable

        @pack = Pack.new
        @pack.owner = @user
        @pack.name = 'IDO%0001 AC 201701 all'
        @pack.save

        @remote_files = ['2pages.pdf', '3pages.pdf', '5pages.pdf'].map do |file_name|
          document = Document.new
          document.pack       = @pack
          document.position   = 1
          document.content    = File.open Rails.root.join('spec/support/files/' + file_name)
          document.origin     = 'upload'
          document.is_a_cover = false
          document.save

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

          SendToFTP.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          expect(@ftp.used?).to eq false
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

          SendToFTP.new(@ftp, @remote_files, max_number_of_threads: 1).execute

          files = Dir.glob("#{temp_dir}/files/iDocus/IDO%0001/201701/AC/*.pdf").sort.map do |path|
            File.basename path
          end

          expect(files).to eq ['2pages.pdf', '3pages.pdf', '5pages.pdf']

          server.stop
        end
      end
    end
  end
end
