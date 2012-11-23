module Delivery
  class << self
    def process(service_prefix)
      service_class = to_service_class(service_prefix)
      service_name = to_service_name(service_prefix)

      processed_user_ids = []
      while RemoteFile.not_processed.of_service(service_name).retryable.first
        remote_file = RemoteFile.not_processed.not_in(user_id: processed_user_ids).of_service(service_name).retryable.first
        unless remote_file
          remote_file = RemoteFile.not_processed.where(service_name: service_name).retryable.first
          processed_user_ids = []
        end
        pack = remote_file.pack
        user = remote_file.user
        remote_files = pack.remote_files.not_processed.of(user, service_name).retryable
        efs = user.find_or_create_efs
        if service_name.in? efs.active_services_name
          puts "[#{service_name}] Synchronising files for user : #{user.info}..."
          remote_files = remote_files.sort do |a,b|
            a.local_name <=> b.local_name
          end
          puts "\t#{pack.name}\t[#{remote_files.count}]"
          efs.send(service_class).sync(remote_files)
          puts "\tDone."
        else
          remote_files.each { |rf| rf.cancel! }
        end
        processed_user_ids << user.id
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
          :the_box
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