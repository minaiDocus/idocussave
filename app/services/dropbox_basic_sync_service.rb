class DropboxBasicSyncService
  def initialize(remote_files)
    @remote_files = remote_files

    @dropbox = remote_files.first.user.external_file_storage.dropbox_basic
  end


  # Keeping the Queue implementation in case it could be used later but DO NOT USE IT
  # Multi Threading dropbox uploads causes API error due to too many concurent sessions
  def sync
    queue = Queue.new
    threads = []
    semaphore = Mutex.new

    @remote_files.each_with_index do |remote_file, index|
      queue << [remote_file, index]
    end

    threads_count = 1
    threads_count = queue.size if queue.size < threads_count

    threads_count.times do
      threads << Thread.new do
        current_client = client

        loop do
          break if queue.empty?

          remote_file, index = queue.pop

          remote_path     = ExternalFileStorage.delivery_path(remote_file, @dropbox.path)
          remote_filepath = File.join(remote_path, remote_file.name)

          description = "\t[#{'%0.3d' % (index + 1)}] \"#{remote_filepath}\""

          tries = 0

          begin
            remote_file.sending!(remote_filepath)

            if is_not_up_to_date(remote_filepath, remote_file.local_path, current_client)
              current_client.put_file(remote_filepath.to_s, open(remote_file.local_path), true)

              semaphore.synchronize { puts "#{description} sent" }
            else
              semaphore.synchronize { puts "#{description} is up to date" }
            end

            remote_file.synced!
          rescue => e
            tries += 1

            semaphore.synchronize { puts "#{description} failed : [#{e.class}] #{e.message}" }
            if tries < 3
              retry
            else
              semaphore.synchronize { puts "#{description} Retrying later" }

              remote_file.not_synced!("[#{e.class}] #{e.message}")
            end
          end
        end
      end
    end

    threads.each(&:join)
    @remote_files.select do |remote_file|
      remote_file.state == 'not_synced'
    end.empty?
  end


  def client
    if @dropbox.is_configured?
      @client ||= DropboxClient.new(@dropbox.access_token, Dropbox::ACCESS_TYPE)
    end
  end


  def is_up_to_date(remote_filepath, filepath, current_client = client)
    path     = File.dirname(remote_filepath)
    filename = File.basename(remote_filepath)

    results = current_client.search(path, filename, 1)

    if results.any?
      size = results.first['bytes']

      if size == File.size(filepath)
        true
      else
        false
      end
    end
  end


  def is_not_up_to_date(remote_filepath, filepath, current_client = client)
    !is_up_to_date(remote_filepath, filepath, current_client)
  end
end
