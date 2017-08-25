# Basic test with FakeFTP server, multi-thread does not work with it

require 'spec_helper'
require 'fake_ftp'

describe SendToFTP do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  describe '#execute' do
    before(:each) do
      @user = FactoryGirl.create :user, code: 'IDO%0001'
      @user.options = UserOptions.create(user_id: @user.id)
      @user.external_file_storage = ExternalFileStorage.create(user_id: @user.id)

      @ftp = @user.external_file_storage.ftp
      @ftp.host     = 'ftp://localhost'
      @ftp.port     = 2121
      @ftp.login    = 'user'
      @ftp.password = 'password'
      @ftp.path     = 'files/iDocus/:code/:year:month/:account_book'
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

      @server = FakeFtp::Server.new(2121, 2020)
      @server.start
    end

    after(:each) do
      @server.stop
    end

    it 'sends 3 files successfully' do
      SendToFTP.new(@ftp, @remote_files, max_number_of_threads: 1).execute

      expect(@server.files.sort).to eq ['2pages.pdf', '3pages.pdf', '5pages.pdf']
    end
  end
end
