class FileDelivery::Storage::Knowings
  def initialize(remote_files)
    @remote_files = remote_files

    @receiver = remote_files.first.receiver
    @knowings = @receiver.knowings
  end


  def execute
    @remote_files.each_with_index do |remote_file, index|
      remote_filepath = File.join(@knowings.url, remote_file.local_name)

      tries = 0

      begin
        remote_file.sending!(remote_filepath)

        number = "\t[#{'%0.3d' % (index + 1)}]"
        info = "#{number}[#{tries + 1}] \"#{remote_filepath}\""
        result = client.put(remote_file.local_path, remote_file.local_name)

        raise Knowings::UnexpectedResponseCode.new result unless result.in? [200, 201]

        System::Log.info('knowings', "#{info} uploaded")

        remote_file.synced!
      rescue => e
        tries += 1

        System::Log.info('knowings', "#{info} upload failed : [#{e.class}] #{e.message}")

        if tries < 2
          retry
        else
          System::Log.info('knowings', "#{number} retrying later")

          remote_file.not_retryable!("[#{e.class}] #{e.message}")
        end
      end
    end
  end

  private

  def client
    @client ||= KnowingsApi::Client.new(@knowings.username, @knowings.password, @knowings.url)
  end
end
