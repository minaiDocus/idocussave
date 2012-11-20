module Delivery
  class << self
    def process(service_prefix)
      service_class = to_service_class(service_prefix)
      service_name = to_service_name(service_prefix)

      User.all.each do |user|
        efs = user.find_or_create_efs
        if service_name.in? efs.active_services_name
          remote_file = RemoteFile.not_processed.of(user, service_name).first
          if remote_file
            puts "[#{service_name}] Synchronising files for user : #{user.info}..."
            pack = remote_file.pack
            remote_files = pack.remote_files.of(user, service_name)
            puts "\t#{pack.name}\t[#{remote_files.count}]"
            efs.send(service_class).sync(remote_files)
            puts "\tDone."
          end
        end
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