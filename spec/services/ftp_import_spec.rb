require 'net/ftp'
require 'ftpd'
require 'spec_helper'

describe FTPImport do
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
    before(:each) do
      DatabaseCleaner.start

      @organization = Organization.create(name: 'iDocus', code: 'IDOC')
      @ftp = Ftp.new(organization: @organization, host: 'ftp://localhost', is_configured: true)
      @user = FactoryGirl.create(:user, code: 'IDOC%0001', organization: @organization)
      @user.options = UserOptions.create(user: @user, is_upload_authorized: true)
      @user2 = FactoryGirl.create(:user, code: 'IDOC%0002', organization: @organization)
      @user2.options = UserOptions.create(user: @user2, is_upload_authorized: true)

      AccountBookType.create(user: @user, name: 'AC', description: '( Achat )')
      AccountBookType.create(user: @user, name: 'VT', description: '( Vente )')
      AccountBookType.create(user: @user2, name: 'AC', description: '( Achat )')
      AccountBookType.create(user: @user2, name: 'VT', description: '( Vente )')
    end

    after(:each) { DatabaseCleaner.clean }

    it 'fails to authenticate' do
      leader = create :prescriber, code: 'IDOC%LEAD', organization: @organization
      @organization.leader = leader
      @organization.save

      Dir.mktmpdir do |temp_dir|
        driver = Driver.new temp_dir, false
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        FTPImport.new(@ftp).execute

        expect(@ftp.is_configured).to eq false
        expect(leader.notifications.size).to eq 1
        expect(leader.notifications.first.notice_type).to eq 'org_ftp_auth_failure'

        server.stop
      end
    end

    it 'creates folders successfully' do
      Dir.mktmpdir do |temp_dir|
        driver = Driver.new temp_dir
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        FTPImport.new(@ftp).execute

        folders = Dir.glob(File.join(temp_dir, 'INPUT', '*'))
        expect(folders.size).to eq 4
        expect(folders.include?(File.join(temp_dir, 'INPUT', 'IDOC%0001 - AC (TeSt)'))).to eq true
        expect(folders.include?(File.join(temp_dir, 'INPUT', 'IDOC%0001 - VT (TeSt)'))).to eq true
        expect(folders.include?(File.join(temp_dir, 'INPUT', 'IDOC%0002 - AC (TeSt)'))).to eq true
        expect(folders.include?(File.join(temp_dir, 'INPUT', 'IDOC%0002 - VT (TeSt)'))).to eq true

        server.stop
      end
    end

    it 'imports a file successfully' do
      Dir.mktmpdir do |temp_dir|
        driver = Driver.new temp_dir
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        FileUtils.mkdir_p File.join(temp_dir, 'INPUT', 'IDOC%0001 - AC (TeSt)')
        FileUtils.cp Rails.root.join('spec/support/files/2pages.pdf'), File.join(temp_dir, 'INPUT', 'IDOC%0001 - AC (TeSt)')

        FTPImport.new(@ftp).execute

        expect(TempDocument.count).to eq 1

        server.stop
      end
    end

    it 'rejects a file' do
      Dir.mktmpdir do |temp_dir|
        driver = Driver.new temp_dir
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        original_file_path = Rails.root.join('spec/support/files/corrupted.pdf')
        file_path = File.join(temp_dir, 'INPUT/IDOC%0001 - AC (TeSt)/corrupted.pdf')
        new_file_path = File.join(temp_dir, 'INPUT/IDOC%0001 - AC (TeSt)/corrupted (erreur fichier non valide pour iDocus).pdf')

        FileUtils.mkdir_p File.join(temp_dir, 'INPUT/IDOC%0001 - AC (TeSt)')
        FileUtils.cp original_file_path, file_path

        FTPImport.new(@ftp).execute

        expect(TempDocument.count).to eq 0
        expect(File.exist?(file_path)).to eq false
        expect(File.exist?(new_file_path)).to eq true

        server.stop
      end
    end

    describe 'given "/path" as root path' do
      before(:each) do
        @root_path = '/path'
        @ftp.update root_path: @root_path
      end

      it 'creates folders successfully' do
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FTPImport.new(@ftp).execute

          folders = Dir.glob(File.join(temp_dir, @root_path, 'INPUT', '*'))
          expect(folders.size).to eq 4
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - AC (TeSt)'))).to eq true
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - VT (TeSt)'))).to eq true
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0002 - AC (TeSt)'))).to eq true
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0002 - VT (TeSt)'))).to eq true

          server.stop
        end
      end

      it 'imports a file successfully' do
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileUtils.mkdir_p File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - AC (TeSt)')
          FileUtils.cp Rails.root.join('spec/support/files/2pages.pdf'), File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - AC (TeSt)')

          FTPImport.new(@ftp).execute

          expect(TempDocument.count).to eq 1

          server.stop
        end
      end
    end

    describe 'given "/path/to/folder" as root path' do
      before(:each) do
        @root_path = '/path/to/folder'
        @ftp.update root_path: @root_path
      end

      it 'creates folders successfully' do
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FTPImport.new(@ftp).execute

          folders = Dir.glob(File.join(temp_dir, @root_path, 'INPUT', '*'))
          expect(folders.size).to eq 4
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - AC (TeSt)'))).to eq true
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - VT (TeSt)'))).to eq true
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0002 - AC (TeSt)'))).to eq true
          expect(folders.include?(File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0002 - VT (TeSt)'))).to eq true

          server.stop
        end
      end

      it 'imports a file successfully' do
        Dir.mktmpdir do |temp_dir|
          driver = Driver.new temp_dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileUtils.mkdir_p File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - AC (TeSt)')
          FileUtils.cp Rails.root.join('spec/support/files/2pages.pdf'), File.join(temp_dir, @root_path, 'INPUT', 'IDOC%0001 - AC (TeSt)')

          FTPImport.new(@ftp).execute

          expect(TempDocument.count).to eq 1

          server.stop
        end
      end
    end
  end
end
