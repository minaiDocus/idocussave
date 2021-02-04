class FileDelivery::DeliverFile
  class << self
    def to(service_prefix)
      service_name  = to_service_name(service_prefix)
      service_class = to_service_class(service_prefix)

      pack_ids = RemoteFile.not_processed.retryable.of_service(service_name).select(:pack_id).distinct

      pack_ids.each do |row|
        FileSender.delay(queue: :file_delivery).execute(row.pack_id, service_name, service_class)
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
      when 'sftp'
        :sftp
      when 'kwg'
        :knowings
      when 'mcf'
        :my_company_files
      else
        :dropbox_basic
      end
    end

    def to_service_name(service_prefix)
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
      when 'sftp'
        RemoteFile::SFTP
      when 'kwg'
        RemoteFile::KNOWINGS
      when 'mcf'
        RemoteFile::MY_COMPANY_FILES
      else
        ''
      end
    end
  end

  class FileSender
    def self.execute(pack_id, service_name, service_class)
      UniqueJobs.for "DeliverFile-#{service_class.to_s}-#{pack_id.to_s}" do
        new(pack_id, service_name, service_class).execute
      end
    end

    def initialize(pack_id, service_name, service_class)
      @pack = Pack.find pack_id
      @service_name = service_name
      @service_class = service_class
    end

    def execute
      if receivers.any?
        receivers.each do |receiver|
          @receiver       = receiver
          @storage        = nil
          @remote_files   = nil
          @services_name  = nil

          if @service_name.in?(services_name) && remote_files.size > 0
            push_files
          else
            remote_files.each(&:cancel!)
          end
        end
      end
    end

    def receivers
      return @receivers unless @recievers.nil?

      user_ids  = @pack.remote_files.of_service(@service_name).joins(:user).pluck('users.id').uniq
      group_ids = @pack.remote_files.of_service(@service_name).joins(:group).pluck('groups.id').uniq
      organization_ids = @pack.remote_files.of_service(@service_name).joins(:organization).pluck('organizations.id').uniq

      @receivers = []

      @receivers << User.where(id: user_ids)   if user_ids.size > 0
      @receivers << Group.where(id: group_ids) if group_ids.size > 0
      @receivers << Organization.where(id: organization_ids) if organization_ids.size > 0

      @receivers.flatten!

      @receivers
    end

    def remote_files
      return @remote_files unless @remote_files.nil?

      @remote_files = @pack.remote_files.not_processed.retryable.of(@receiver, @service_name).to_a

      @remote_files.each do |remote_file|
        unless remote_file.remotable_type == 'Pack::Report' || (remote_file.remotable.try(:cloud_content).try(:attached?) && remote_file.try(:local_name).present?)
          remote_file.cancel!

          @remote_files.reject! { |rf| rf.id == remote_file.id }
        end
      end

      @remote_files
    end

    def services_name
      return @services_name unless @services_name.nil?

      @services_name = []

      if @receiver.class.name == User.name
        efs = @receiver.find_or_create_external_file_storage

        @services_name = efs.active_services_name
      elsif @receiver.class.name == Organization.name
        @services_name << RemoteFile::KNOWINGS if @receiver.knowings.try(:is_configured?)
        @services_name << RemoteFile::FTP if @receiver.ftp.try(:configured?)
        @services_name << RemoteFile::SFTP if @receiver.sftp.try(:configured?)
        @services_name << RemoteFile::MY_COMPANY_FILES if @receiver.mcf_settings.try(:ready?)
      else
        @services_name = ['Dropbox Extended']
      end

      @services_name
    end

    def storage
      return @storage unless @storage.nil?

      @storage = @receiver.external_file_storage.send(@service_class) unless @receiver.class.in? [Group, Organization]
      @storage = @receiver.ftp if @receiver.class == Organization && @receiver.ftp.try(:configured?) && @service_class == :ftp
      @storage = @receiver.sftp if @receiver.class == Organization && @receiver.sftp.try(:configured?) && @service_class == :sftp

      @storage
    end

    def push_to_mcf
      mcf_storage = @pack.owner.mcf_storage

      if mcf_storage.present?
        path_pattern = Pathname.new '/' + mcf_storage
        path_pattern = path_pattern.join @receiver.mcf_settings.delivery_path_pattern.sub(/\A\//, '')
        FileDelivery::Storage::Mcf.new(@receiver.mcf_settings, remote_files, path_pattern: path_pattern.to_s, max_retries: 1).execute
      else
        remote_files.each(&:cancel!)
      end
    end

    def push_files
      System::Log.info('processing', "[#{@service_name}][#{remote_files.first.receiver_info}] #{@pack.name} - #{remote_files.size} - SYNC START")
      start_time = Time.now

      if @receiver.class.name == Group.name || @service_class == :dropbox_extended
        FileDelivery::Storage::Dropbox.new(DropboxExtended, remote_files, path_pattern: @receiver.dropbox_delivery_folder).execute
      else
        case @service_class
        when :knowings
          FileDelivery::Storage::Knowings.new(remote_files).execute
        when :my_company_files
          push_to_mcf
        when :dropbox_basic
          FileDelivery::Storage::Dropbox.new(storage, remote_files).execute
        when :box
          FileDelivery::Storage::Box.new(remote_files).sync
        when :ftp
          FileDelivery::Storage::Ftp.new(storage, remote_files).execute
        when :sftp
          FileDelivery::Storage::Sftp.new(storage, remote_files).execute
        when :google_doc
          FileDelivery::Storage::GoogleDrive.new(storage).sync(remote_files)
        end
      end

      total_synced = remote_files.select { |e| e.state == 'synced' }.size
      System::Log.info('processing', "[#{@service_name}][#{remote_files.first.receiver_info}] #{@pack.name} - #{total_synced}/#{remote_files.size} - SYNC END (#{(Time.now - start_time).round(3)}s)")
    end
  end
end
