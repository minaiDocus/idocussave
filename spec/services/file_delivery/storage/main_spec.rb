require 'spec_helper'

class FileDelivery::Storage::Main::TestError < RuntimeError; end

describe FileDelivery::Storage::Main do
  # Disable transactionnal database clean, needed for multi-thread
  before(:all) { DatabaseCleaner.clean }
  after(:all)  { DatabaseCleaner.start }
  # And clean with truncation instead
  after(:each) { DatabaseCleaner.clean_with(:truncation) }

  before(:each) do
    class SendToOnlineStorage < FileDelivery::Storage::Main
      def execute
        run do
          # it does nothing
        end
      end

      private

      def max_number_of_threads
        1
      end

      def up_to_date?
        false
      end

      def retryable_failure?(error)
        true
      end

      def manageable_failure?(error)
        false
      end

      def manage_failure(error)
        nil
      end
    end

    @user = FactoryBot.create :user, code: 'IDO%0001'
    @user.options = UserOptions.create(user_id: @user.id)

    @pack = Pack.new
    @pack.owner = @user
    @pack.name = 'IDO%0001 AC 201701 all'
    @pack.save
  end

  it 'works', :works do
    document = Document.new
    document.pack           = @pack
    document.position       = 1
    document.content        = File.open Rails.root.join('spec/support/files/2pages.pdf')
    document.origin         = 'upload'
    document.is_a_cover     = false
    document.save

    remote_file              = RemoteFile.new
    remote_file.receiver     = @user
    remote_file.pack         = @pack
    remote_file.service_name = 'Dropbox'
    remote_file.remotable    = document
    remote_file.save

    expect(remote_file.state).to eq 'waiting'

    SendToOnlineStorage.new(DropboxBasic.new, [remote_file]).execute

    expect(remote_file.state).to eq 'synced'
  end

  it 'runs concurrently', :runs_concurrently do
    allow_any_instance_of(Storage::Metafile).to receive(:path).and_return('/path/to/file.pdf')

    remote_files = 5.times.map do |i|
      remote_file              = RemoteFile.new
      remote_file.receiver     = @user
      remote_file.pack         = @pack
      remote_file.service_name = 'Dropbox'
      remote_file.save
      remote_file
    end

    class SendToOnlineStorage
      def execute
        run do
          sleep(1)
        end
      end

      def max_number_of_threads
        10
      end
    end

    result = Benchmark.measure do
      SendToOnlineStorage.new(DropboxBasic.new, remote_files).execute
    end

    expect(result.real < 1.5).to eq true
  end

  it 'handles error', :handles_error do
    remote_file              = RemoteFile.new
    remote_file.receiver     = @user
    remote_file.pack         = @pack
    remote_file.service_name = 'Dropbox'
    remote_file.save

    allow_any_instance_of(Storage::Metafile).to receive(:path).and_return('/path/to/file.pdf')

    class SendToOnlineStorage
      def execute
        @is_error_raised = false
        run do
          metafile.begin
          unless @is_error_raised
            @is_error_raised = true
            raise FileDelivery::Storage::Main::TestError
          end
          metafile.success
        end
      end

      def retryable_failure?(error)
        error.class == FileDelivery::Storage::Main::TestError
      end
    end

    expect_any_instance_of(Storage::Metafile).to receive(:begin).twice
    expect_any_instance_of(Storage::Metafile).to receive(:success).once

    SendToOnlineStorage.new(DropboxBasic.new, [remote_file]).execute
  end

  it 'manages errors', :manages_errors do
    remote_files = 2.times.map do
      remote_file              = RemoteFile.new
      remote_file.receiver     = @user
      remote_file.pack         = @pack
      remote_file.service_name = 'Dropbox'
      remote_file.save
      remote_file
    end

    allow_any_instance_of(Storage::Metafile).to receive(:path).and_return('/path/to/file.pdf')

    class SendToOnlineStorage
      def execute
        run do
          raise FileDelivery::Storage::Main::TestError
        end
      end

      def retryable_failure?(error)
        false
      end

      def manageable_failure?(error)
        error.class == FileDelivery::Storage::Main::TestError
      end

      def manage_failure(error)
      end
    end

    expect(remote_files[0]).to receive(:not_retryable!).once
    expect(remote_files[1]).to receive(:not_retryable!).once
    expect_any_instance_of(SendToOnlineStorage).to receive(:manage_failure).once

    SendToOnlineStorage.new(DropboxBasic.new, remote_files).execute
  end

  it 'raises an exception', :raises_an_exceptions do
    remote_file              = RemoteFile.new
    remote_file.receiver     = @user
    remote_file.pack         = @pack
    remote_file.service_name = 'Dropbox'
    remote_file.save
    remote_file

    allow_any_instance_of(Storage::Metafile).to receive(:path).and_return('/path/to/file.pdf')

    class SendToOnlineStorage
      def execute
        run do
          raise FileDelivery::Storage::Main::TestError
        end
      end

      def retryable_failure?(error)
        false
      end

      def manageable_failure?(error)
        false
      end
    end

    expect do
      SendToOnlineStorage.new(DropboxBasic.new, [remote_file]).execute
    end.to raise_error(FileDelivery::Storage::Main::TestError)
  end
end
