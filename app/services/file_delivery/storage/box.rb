class FileDelivery::Storage::Box
  def initialize(remote_files)
    @remote_files = remote_files
    @box = remote_files.first.user.external_file_storage.box
  end

  def sync
    @remote_files.each_with_index do |remote_file, index|
      remote_path = ExternalFileStorage.delivery_path(remote_file, @box.path)
      remote_filepath = File.join(remote_path, remote_file.name)
      tries = 0

      begin
        @folder ||= @box.client.create_folder remote_path

        if @folder
          remote_file.sending!(remote_filepath)

          print "\t[#{'%0.3d' % (index + 1)}] \"#{remote_filepath}\" "
          if is_not_up_to_date?(@folder, remote_file.name, remote_file.local_path)
            print 'sending...'

            ::File.open(remote_file.local_path, 'rb') do |data|
              @folder.upload_file(remote_file.name, data)
            end

            print "done\n"
          else
            print "is up to date\n"
          end

          remote_file.synced!
        end
      rescue => e
        tries += 1
        print "failed : [#{e.class}] #{e.message}\n"
        if tries < 3
          retry
        else
          puts "\t[#{'%0.3d' % (index + 1)}] Retrying later"

          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end
      end
    end
    @folder = nil
  end

  def is_up_to_date?(folder, file_name, file_path)
    files = folder.files.select { |e| e.name == file_name }

    files.any? && files.first.size == File.size(file_path) ? true : false
  end

  def is_not_up_to_date?(folder, file_name, file_path)
    !is_up_to_date?(folder, file_name, file_path)
  end
end
