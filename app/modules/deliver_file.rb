module DeliverFile
  def self.to(service_prefix)
    service_name  = to_service_name(service_prefix)
    service_class = to_service_class(service_prefix)

    processed_receiver_ids = []

    while RemoteFile.not_processed.of_service(service_name).retryable.first
      remote_file = RemoteFile.not_processed.where.not(user_id: processed_receiver_ids,
                                                       group_id: processed_receiver_ids,
                                                       organization_id: processed_receiver_ids).of_service(service_name).retryable.first

      unless remote_file
        remote_file = RemoteFile.not_processed.where(service_name: service_name).retryable.first
        processed_receiver_ids = []
      end

      pack         = remote_file.pack
      receiver     = remote_file.receiver
      storage      = nil

      unless receiver
        remote_file.cancel!
      else
        remote_files = pack.remote_files.not_processed.of(receiver, service_name).retryable

        storage = receiver.external_file_storage.send(service_class) unless receiver.class.in? [Group, Organization]
        storage = receiver.ftp if receiver.class == Organization && receiver.ftp.try(:configured?) && service_class == :ftp

        if receiver.class.name == User.name
          efs = receiver.find_or_create_external_file_storage

          services_name = efs.active_services_name
        elsif receiver.class.name == Organization.name
          services_name = []
          services_name << RemoteFile::KNOWINGS if receiver.knowings.try(:is_configured?)
          services_name << RemoteFile::FTP if receiver.ftp.try(:configured?)
          services_name << RemoteFile::MY_COMPANY_FILES if receiver.mcf_settings.try(:configured?)
        else
          services_name = ['Dropbox Extended']
        end

        if service_name.in?(services_name)
          logger.info "[#{service_name}][#{remote_file.receiver_info}] #{pack.name} - #{remote_files.size} - SYNC START"
          start_time = Time.now

          remote_files = remote_files.sort do |a, b|
            a.local_name <=> b.local_name
          end

          if receiver.class.name == Group.name || service_class == :dropbox_extended
            SendToDropbox.new(DropboxExtended, remote_files, path_pattern: receiver.dropbox_delivery_folder, logger: logger).execute
          elsif service_class == :knowings
            KnowingsSyncService.new(remote_files).execute
          elsif service_class == :my_company_files
            mcf_storage = remote_files.first.pack.owner.mcf_storage
            if mcf_storage.present?
              path_pattern = Pathname.new '/' + mcf_storage
              path_pattern = path_pattern.join receiver.mcf_settings.delivery_path_pattern.sub(/\A\//, '')
              SendToMcf.new(receiver.mcf_settings, remote_files, path_pattern: path_pattern.to_s, logger: logger, max_retries: 1).execute
            else
              remote_files.each(&:cancel!)
            end
          elsif service_class == :dropbox_basic
            SendToDropbox.new(storage, remote_files, logger: logger).execute
          elsif service_class == :box
            BoxSyncService.new(remote_files).sync
          elsif service_class == :ftp
            SendToFTP.new(storage, remote_files, logger: logger).execute
          elsif service_class == :google_doc
            GoogleDriveSyncService.new(storage).sync(remote_files)
          end

          total_synced = remote_files.select { |e| e.state == 'synced' }.size
          logger.info "[#{service_name}][#{remote_file.receiver_info}] #{pack.name} - #{total_synced}/#{remote_files.size} - SYNC END (#{(Time.now - start_time).round(3)}s)"
        else
          remote_files.each(&:cancel!)
        end

        processed_receiver_ids << receiver.id
      end
    end
  end


  def self.to_service_class(service_prefix)
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
    when 'kwg'
      :knowings
    when 'mcf'
      :my_company_files
    else
      :dropbox_basic
    end
  end


  def self.to_service_name(service_prefix)
    case service_prefix
    when 'dbb'
      RemoteFile::DROPBOX
    when 'dbx'
      RemoteFile::DROPBOX_EXTENDED
    when 'gdr'
      RemoteFile::GOOGLE_DRIVE
    when 'box'
      RemoteFile::BOX
    when 'ftp'
      RemoteFile::FTP
    when 'kwg'
      RemoteFile::KNOWINGS
    when 'mcf'
      RemoteFile::MY_COMPANY_FILES
    else
      ''
    end
  end

  def self.logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_processing.log")
  end
end
