require 'net/ftp'
require 'ftpd'
require 'spec_helper'

describe FileImport::Ftp do
  class Driver
    def initialize(dir, is_authenticatable=true)
      @dir = dir
      @is_authenticatable = is_authenticatable
    end

    def authenticate(user, password)
      @is_authenticatable
    end

    def file_system(user)
      Ftpd::DiskFileSystem.new @dir
    end
  end

  describe '#execute' do
    before(:each) do
      DatabaseCleaner.start

      @organization = Organization.create(name: 'iDocus', code: 'IDOC')
      @ftp = Ftp.new(organization: @organization, host: 'ftp://localhost', is_configured: true)
      @user = FactoryBot.create(:user, code: 'IDOC%0001', organization: @organization)
      @user.options = UserOptions.create(user: @user, is_upload_authorized: true)
      @user2 = FactoryBot.create(:user, code: 'IDOC%0002', organization: @organization)
      @user2.options = UserOptions.create(user: @user2, is_upload_authorized: true)

      @subscription = Subscription.create(user: @user, organization: @organization, period_duration: 1)

      AccountBookType.create(user: @user, name: 'AC', description: '( Achat )')
      AccountBookType.create(user: @user, name: 'VT', description: '( Vente )')
      AccountBookType.create(user: @user2, name: 'AC', description: '( Achat )')
      AccountBookType.create(user: @user2, name: 'VT', description: '( Vente )')

      Settings.create(notify_errors_to: ['jean@idocus.com'])
    end

    after(:each) { DatabaseCleaner.clean }

    it 'fails to authenticate' do
      leader = create :user, is_prescriber: true, organization: @organization
      leader.create_notify
      Member.create(user: leader, organization: @organization, code: 'IDOC%LEAD', role: Member::ADMIN)

      CustomUtils.mktmpdir do |dir|
        driver = Driver.new dir, false
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        FileImport::Ftp.new(@ftp).execute

        expect(@ftp.is_configured).to eq false
        expect(leader.notifications.size).to eq 1
        expect(leader.notifications.first.notice_type).to eq 'org_ftp_auth_failure'

        server.stop
      end
    end

    it 'creates folders successfully' do
      CustomUtils.mktmpdir do |dir|
        driver = Driver.new dir
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        FileImport::Ftp.new(@ftp).execute

        folders = Dir.glob(File.join(dir, 'INPUT', '*'))
        expect(folders.size).to eq 4
        expect(folders.include?(File.join(dir, 'INPUT', 'IDOC%0001 - AC (Test)'))).to eq true
        expect(folders.include?(File.join(dir, 'INPUT', 'IDOC%0001 - VT (Test)'))).to eq true
        expect(folders.include?(File.join(dir, 'INPUT', 'IDOC%0002 - AC (Test)'))).to eq true
        expect(folders.include?(File.join(dir, 'INPUT', 'IDOC%0002 - VT (Test)'))).to eq true

        server.stop
      end
    end

    it 'imports a file successfully' do
      CustomUtils.mktmpdir do |dir|
        driver = Driver.new dir
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        FileUtils.mkdir_p File.join(dir, 'INPUT', 'IDOC%0001 - AC (Test)')
        FileUtils.cp Rails.root.join('spec/support/files/2pages.pdf'), File.join(dir, 'INPUT', 'IDOC%0001 - AC (Test)')

        FileImport::Ftp.new(@ftp).execute

        expect(TempDocument.count).to eq 1

        server.stop
      end
    end

    it 'rejects a file' do
      CustomUtils.mktmpdir do |dir|
        driver = Driver.new dir
        server = Ftpd::FtpServer.new driver
        server.start
        @ftp.update port: server.bound_port

        original_file_path = Rails.root.join('spec/support/files/corrupted.pdf')
        file_path = File.join(dir, 'INPUT/IDOC%0001 - AC (Test)/corrupted.pdf')
        new_file_path = File.join(dir, 'INPUT/IDOC%0001 - AC (Test)/corrupted (fichier corrompu ou protégé par mdp).pdf')

        FileUtils.mkdir_p File.join(dir, 'INPUT/IDOC%0001 - AC (Test)')
        FileUtils.cp original_file_path, file_path

        FileImport::Ftp.new(@ftp).execute

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
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileImport::Ftp.new(@ftp).execute

          folders = Dir.glob(File.join(dir, @root_path, 'INPUT', '*'))
          expect(folders.size).to eq 4
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - AC (Test)'))).to eq true
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - VT (Test)'))).to eq true
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0002 - AC (Test)'))).to eq true
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0002 - VT (Test)'))).to eq true

          server.stop
        end
      end

      it 'imports a file successfully' do
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileUtils.mkdir_p File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - AC (Test)')
          FileUtils.cp Rails.root.join('spec/support/files/2pages.pdf'), File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - AC (Test)')

          FileImport::Ftp.new(@ftp).execute

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
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileImport::Ftp.new(@ftp).execute

          folders = Dir.glob(File.join(dir, @root_path, 'INPUT', '*'))
          expect(folders.size).to eq 4
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - AC (Test)'))).to eq true
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - VT (Test)'))).to eq true
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0002 - AC (Test)'))).to eq true
          expect(folders.include?(File.join(dir, @root_path, 'INPUT', 'IDOC%0002 - VT (Test)'))).to eq true

          server.stop
        end
      end

      it 'imports a file successfully' do
        CustomUtils.mktmpdir do |dir|
          driver = Driver.new dir
          server = Ftpd::FtpServer.new driver
          server.start
          @ftp.update port: server.bound_port

          FileUtils.mkdir_p File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - AC (Test)')
          FileUtils.cp Rails.root.join('spec/support/files/2pages.pdf'), File.join(dir, @root_path, 'INPUT', 'IDOC%0001 - AC (Test)')

          FileImport::Ftp.new(@ftp).execute

          expect(TempDocument.count).to eq 1

          server.stop
        end
      end
    end
  end
end
