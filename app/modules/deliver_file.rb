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
      storage      = receiver.external_file_storage.send(service_class)
      remote_files = pack.remote_files.not_processed.of(receiver, service_name).retryable

      if receiver.class.name == User.name
        efs = receiver.find_or_create_external_file_storage

        services_name = efs.active_services_name
      elsif receiver.class.name == Organization.name
        services_name = if receiver.knowings.try(:is_configured?)
                          ['Knowings']
                        else
                          []
                        end
      else
        services_name = ['Dropbox Extended']
      end

      if service_name.in?(services_name)
        logger.info "[#{service_name}][#{remote_file.receiver_info}] #{pack.name} - #{remote_files.size} - SYNC START"

        remote_files = remote_files.sort do |a, b|
          a.local_name <=> b.local_name
        end

        if receiver.class.name == Group.name || service_class == :dropbox_extended
          SendToDropbox.new(storage, remote_files, path_pattern: receiver.dropbox_delivery_folder, logger: logger).execute
        elsif receiver.class.name == Organization.name
          KnowingsSyncService.new(remote_files).execute
        elsif service_class == :dropbox_basic
          SendToDropbox.new(storage, remote_files, logger: logger).execute
        elsif service_class == :box
          BoxSyncService.new(remote_files).sync
        elsif service_class == :ftp
          FtpSyncService.new(remote_files).execute
        elsif service_class == :google_doc
          GoogleDriveSyncService.new(storage).sync(remote_files)
        end

        total_synced = remote_files.select { |e| e.state == 'synced' }.size
        logger.info "[#{service_name}][#{remote_file.receiver_info}] #{pack.name} - #{total_synced}/#{remote_files.size} - SYNC END"
      else
        remote_files.each(&:cancel!)
      end

      processed_receiver_ids << receiver.id
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
    else
      :dropbox_basic
    end
  end


  def self.to_service_name(service_prefix)
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
    when 'kwg'
      'Knowings'
    else
      ''
    end
  end

  def self.logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_file_delivery.log")
  end
end
