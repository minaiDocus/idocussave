module DeliverFile
  def self.to(service_prefix)
    service_name  = to_service_name(service_prefix)
    service_class = to_service_class(service_prefix)

    packs = Pack.joins(:remote_files).where('remote_files.state = ? AND remote_files.service_name = ?', 'waiting', service_name)

    packs.each do |pack|
      receivers = generate_receivers(pack, service_name)

      next if receivers.empty?

      receivers.each do |receiver|
        storage       = generate_storage(receiver, service_class)
        remote_files  = generate_remote_files_to_sync(pack, receiver, service_name)
        services_name = check_allowed_services(receiver)

        if service_name.in?(services_name) && remote_files.size > 0
          push_files(pack, receiver, service_class, service_name, remote_files, storage)
        else
          remote_files.each(&:cancel!)
        end
      end
    end
  end

  def self.generate_receivers(pack, service_name)
    user_ids  = pack.remote_files.of_service(service_name).joins(:user).pluck('users.id').uniq
    group_ids = pack.remote_files.of_service(service_name).joins(:group).pluck('groups.id').uniq
    organization_ids = pack.remote_files.of_service(service_name).joins(:organization).pluck('organizations.id').uniq

    receivers = []

    receivers << User.where(id: user_ids)   if user_ids.size > 0
    receivers << Group.where(id: group_ids) if group_ids.size > 0
    receivers << Organization.where(id: organization_ids) if organization_ids.size > 0

    receivers.flatten!

    receivers
  end


  def self.generate_remote_files_to_sync(pack, receiver, service_name)
    remote_files = pack.remote_files.waiting.of(receiver, service_name).retryable.to_a      

    remote_files.each do |remote_file|
      unless remote_file.remotable_type == 'Pack::Report' || (remote_file.remotable.cloud_content.attached? && remote_file.local_name.present?)
        remote_file.cancel!

        remote_files.reject! { |rf| rf.id == remote_file.id }
      end
    end

    remote_files
  end


  def self.generate_storage(receiver, service_class)
    storage = receiver.external_file_storage.send(service_class) unless receiver.class.in? [Group, Organization]
    storage = receiver.ftp if receiver.class == Organization && receiver.ftp.try(:configured?) && service_class == :ftp

    storage
  end


  def self.check_allowed_services(receiver)
    services_name = []

    if receiver.class.name == User.name
      efs = receiver.find_or_create_external_file_storage

      services_name = efs.active_services_name
    elsif receiver.class.name == Organization.name
      services_name << RemoteFile::KNOWINGS if receiver.knowings.try(:is_configured?)
      services_name << RemoteFile::FTP if receiver.ftp.try(:configured?)
      services_name << RemoteFile::MY_COMPANY_FILES if receiver.mcf_settings.try(:configured?)
    else
      services_name = ['Dropbox Extended']
    end

    services_name
  end

  def self.push_to_mcf(pack, receiver, remote_files)
    mcf_storage = pack.owner.mcf_storage

    if mcf_storage.present?
      path_pattern = Pathname.new '/' + mcf_storage
      path_pattern = path_pattern.join receiver.mcf_settings.delivery_path_pattern.sub(/\A\//, '')
      SendToMcf.new(receiver.mcf_settings, remote_files, path_pattern: path_pattern.to_s, logger: logger, max_retries: 1).execute
    else
      remote_files.each(&:cancel!)
    end
  end


  def self.push_files(pack, receiver, service_class, service_name, remote_files, storage)
    logger.info "[#{service_name}][#{remote_files.first.receiver_info}] #{pack.name} - #{remote_files.size} - SYNC START"
    start_time = Time.now

    if receiver.class.name == Group.name || service_class == :dropbox_extended
      SendToDropbox.new(DropboxExtended, remote_files, path_pattern: receiver.dropbox_delivery_folder, logger: logger).execute
    else
      case service_class
      when :knowings
        KnowingsSyncService.new(remote_files).execute
      when :my_company_files
        push_to_mcf(pack, receiver, remote_files)
      when :dropbox_basic
        SendToDropbox.new(storage, remote_files, logger: logger).execute
      when :box
        BoxSyncService.new(remote_files).sync
      when :ftp
        SendToFTP.new(storage, remote_files, logger: logger).execute
      when :google_doc
        GoogleDriveSyncService.new(storage).sync(remote_files)
      end      
    end

    total_synced = remote_files.select { |e| e.state == 'synced' }.size
    logger.info "[#{service_name}][#{remote_files.first.receiver_info}] #{pack.name} - #{total_synced}/#{remote_files.size} - SYNC END (#{(Time.now - start_time).round(3)}s)"
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
