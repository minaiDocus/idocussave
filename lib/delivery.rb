module Delivery
  class << self
    def process(service_prefix)
      service_class = to_service_class(service_prefix)
      service_name = to_service_name(service_prefix)

      processed_receiver_ids = []
      while RemoteFile.not_processed.of_service(service_name).retryable.first
        remote_file = RemoteFile.not_processed.not_in(user_id: processed_receiver_ids, group_id: processed_receiver_ids).of_service(service_name).retryable.first
        unless remote_file
          remote_file = RemoteFile.not_processed.where(service_name: service_name).retryable.first
          processed_receiver_ids = []
        end
        pack = remote_file.pack
        receiver = remote_file.receiver
        remote_files = pack.remote_files.not_processed.of(receiver, service_name).retryable
        if receiver.class.name == User.name
          efs = receiver.find_or_create_efs
          services_name = efs.active_services_name
          is_group = false
        else
          services_name = ['Dropbox Extended']
          is_group = true
        end
        if service_name.in? services_name
          puts "[#{service_name}] Synchronising files for #{receiver.class.name.downcase} : #{receiver.info}..."
          remote_files = remote_files.sort do |a,b|
            a.local_name <=> b.local_name
          end
          puts "\t#{pack.name}\t[#{remote_files.count}]"
          if is_group
            DropboxExtended.sync(remote_files)
          else
            efs.send(service_class).sync(remote_files)
          end
          puts "\tDone."
        else
          remote_files.each { |rf| rf.cancel! }
        end
        processed_receiver_ids << receiver.id
      end
    end

    def to_service_class(service_prefix)
      case service_prefix
        when 'dbb'
          :dropbox_basic
        when 'dbx'
          :dropbox_extended
        when 'gdr'
          :google_doc
        when 'box'
          :box
        when 'ftp'
          :ftp
        else
          :dropbox_basic
      end
    end

    def to_service_name(service_prefix)
      case service_prefix
        when 'dbb'
          'Dropbox'
        when 'dbx'
          'Dropbox Extended'
        when 'gdr'
          'Google Drive'
        when 'box'
          'Box'
        when 'ftp'
          'FTP'
        else
          ''
      end
    end
  end
end