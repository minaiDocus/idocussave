class FileDeliveryInit
  def self.prepare(object, options={})
    options = { type: RemoteFile::ALL, force: false, delay: false }.merge(options).with_indifferent_access
    if object.class.name == Pack.name
      pack = object
    elsif object.class.name == Pack::Report.name
      options[:type] = RemoteFile::REPORT
      pack = object.pack
    end
    pack.extend RemotePack
    if options[:users].present?
      users = options.delete(:users)
      users.each do |user|
        pack.init_delivery_for(user, options)
      end
    elsif options[:groups].present?
      groups = options.delete(:groups)
      groups.each do |group|
        pack.init_delivery_for(group, options)
      end
    else
      owner = pack.owner
      pack.init_delivery_for(owner, options)
      owner.prescribers.each do |prescriber|
        pack.init_delivery_for(prescriber, options)
      end
      owner.groups.each do |group|
        if group.is_dropbox_authorized
          pack.init_delivery_for(group, options)
        end
      end
    end
  end

  module RemotePack
    def init_delivery_for(object, options)
      if options[:delay]
        Delayed::Job.enqueue FileDeliveryJob.new(self, object, options)
      else
        init_delivery(object, options)
      end
    end

    def init_delivery(object, options)
      type = options[:type]
      force = options[:force]
      current_remote_files = []
      if object.class.name == User.name
        services_name = object.find_or_create_efs.active_services_name
      else
        services_name = ['Dropbox Extended']
      end
      services_name.each do |service_name|
        # original
        if type.in? [RemoteFile::ALL, RemoteFile::ORIGINAL_ONLY]
          document = original_document
          document.extend FileDeliveryInit::RemoteFile
          temp_remote_files = document.get_remote_files(object,service_name)
          temp_remote_files.each do |remote_file|
            remote_file.waiting!
          end
          current_remote_files += temp_remote_files
        end
        # pieces
        if type.in? [RemoteFile::ALL, RemoteFile::PIECES_ONLY]
          pieces.each do |piece|
            piece.extend FileDeliveryInit::RemoteFile
            temp_remote_files = piece.get_remote_files(object,service_name)
            if force
              temp_remote_files.each do |remote_file|
                remote_file.waiting!
              end
            end
            current_remote_files += temp_remote_files
          end
        end
        # report
        if type.in?([RemoteFile::ALL, RemoteFile::REPORT]) && report
          report.extend FileDeliveryInit::RemoteReport
          temp_remote_files = report.get_remote_files(object,service_name)
          if force
            temp_remote_files.each do |remote_file|
              remote_file.waiting!
            end
          end
          current_remote_files += temp_remote_files
        end
      end
      current_remote_files
    end
  end

  module RemoteFile
    ALL           = 0
    ORIGINAL_ONLY = 1
    PIECES_ONLY   = 2
    REPORT        = 3

    def get_tiff_file
      file_path = self.content.path
      temp_path = "/tmp/#{self.content_file_name.sub(/\.pdf$/,'.tiff')}"
      PdfDocument::Utils.generate_tiff_file(file_path, temp_path)
      temp_path
    end

    def get_remote_file(object,service_name,extension='.pdf')
      remote_file = remote_files.of(object,service_name).with_extension(extension).first
      unless remote_file
        remote_file = ::RemoteFile.new
        remote_file.receiver = object
        remote_file.pack = self.pack
        remote_file.service_name = service_name
        if extension == '.pdf'
          remote_file.remotable = self
        elsif extension == '.tiff'
          remote_file.temp_path = get_tiff_file
        end
        remote_file.save
        remote_file
      end
      remote_file
    end

    def get_remote_files(object,service_name)
      current_remote_files = []
      if service_name == 'Dropbox Extended'
        if object.file_type_to_deliver.in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::PDF, nil]
          current_remote_files << get_remote_file(object,service_name,'.pdf')
        end
        if object.file_type_to_deliver.in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::TIFF]
          current_remote_files << get_remote_file(object,service_name,'.tiff')
        end
      else
        if object.external_file_storage.get_service_by_name(service_name).try(:file_type_to_deliver).in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::PDF, nil]
          current_remote_files << get_remote_file(object,service_name,'.pdf')
        end
        if object.external_file_storage.get_service_by_name(service_name).try(:file_type_to_deliver).in? [ExternalFileStorage::ALL_TYPES, ExternalFileStorage::TIFF]
          current_remote_files << get_remote_file(object,service_name,'.tiff')
        end
      end
      current_remote_files
    end
  end

  module RemoteReport
    def get_remote_files(object, service_name)
      current_remote_files = []
      if object.class.name == User.name
        filespath = generate_files(object)
      else
        filespath = generate_files
      end
      filespath.each do |filepath|
        remote_file = remote_files.of(object,service_name).where(temp_path: filepath).first
        unless remote_file
          remote_file = ::RemoteFile.new
          remote_file.receiver = object
          remote_file.remotable = self
          remote_file.pack = self.pack
          remote_file.service_name = service_name
          remote_file.temp_path = filepath
          remote_file.save
        end
        current_remote_files << remote_file
      end
      current_remote_files
    end
  end
end

class FileDeliveryJob < Struct.new(:pack, :object, :options)
  def perform
    pack.extend FileDeliveryInit::RemotePack
    pack.init_delivery(object, options)
  end
end