class KnowingsSyncService
  def initialize(remote_files)
    @remote_files = remote_files

    @receiver = remote_files.first.receiver
    @knowings = @receiver.knowings
  end


  def execute
    log = Logger.new(STDOUT)


    @remote_files.each_with_index do |remote_file, index|
      remote_filepath = File.join(@knowings.url, remote_file.local_name)

      tries = 0

      begin
        remote_file.sending!(remote_filepath)

        number = "\t[#{'%0.3d' % (index + 1)}]"
        info = "#{number}[#{tries + 1}] \"#{remote_filepath}\""
        result = client.put(remote_file.local_path, remote_file.local_name)

        raise UnexpectedResponseCode.new result unless result.in? [200, 201]

        log.info { "#{info} uploaded" }

        remote_file.synced!
      rescue => e
        tries += 1

        log.info { "#{info} upload failed : [#{e.class}] #{e.message}" }

        if tries < 3
          retry
        else
          log.info { "#{number} retrying later" }

          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
      end
    end
  end

  private


  def client
    @client ||= KnowingsApi::Client.new(@knowings.username, @knowings.password, @knowings.url)
  end
end