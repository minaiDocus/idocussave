# -*- encoding : UTF-8 -*-
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
      pack.init_delivery_for(owner, options) if options[:type] != RemoteFile::REPORT
      if options[:type] != RemoteFile::REPORT && owner.organization.try(:knowings).try(:ready?)
        pack.init_delivery_for(owner.organization, options.merge(type: RemoteFile::PIECES_ONLY))
      end
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
        Delayed::Job.enqueue ::FileDeliveryJob.new(self, object, options)
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
      elsif object.class.name == Organization.name
        services_name = ['Knowings']
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
        if type == RemoteFile::REPORT && report
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
      DocumentTools.generate_tiff_file(file_path, temp_path)
      temp_path
    end

    def kzip_options
      user = self.pack.owner
      knowings = user.organization.knowings
      _preseizures = self.preseizures
      _preseizures = [nil] unless _preseizures.any?
      _preseizures.map do |preseizure|
        if preseizure
          period = preseizure.date.to_date
        else
          period = DocumentTools.to_period(self.name)
        end
        exercice = ExerciceService.find(user, period, false)
        domain = user.account_book_types.where(name: journal).first.try(:domain)
        nature = nil
        if domain == 'AC - Achats'
          nature = 'Autres'
        elsif domain == 'BQ - Banque'
          nature = 'Relevés'
        end
        options = {}
        options[:user_code]       = user.knowings_code.presence || user.code
        options[:visibility]      = user.knowings_visibility
        options[:user_company]    = user.company
        if exercice
          options[:exercice]      = true
          options[:start_time]    = exercice.start_date.to_time
          options[:end_time]      = exercice.end_date.to_time
        else
          options[:exercice]      = false
        end
        options[:date]            = period.to_time
        options[:tiers]           = preseizure.try(:third_party) if knowings.is_third_party_included
        options[:domain]          = domain
        options[:nature]          = nature
        options[:is_pre_assigned] = preseizure.present? if knowings.is_pre_assignment_state_included
        options[:file_name]       = DocumentTools.file_name self.name
        options.with_indifferent_access
      end
    end

    def get_kzip_file
      KnowingsApi::File.create(self.content.path, kzip_options)
    end

    def get_remote_file(object, service_name, extension='.pdf')
      remote_file = remote_files.of(object, service_name).with_extension(extension).first
      unless remote_file
        remote_file              = ::RemoteFile.new
        remote_file.receiver     = object
        remote_file.pack         = self.pack
        remote_file.service_name = service_name
        if extension == '.pdf'
          remote_file.remotable = self
        elsif extension == '.tiff'
          remote_file.extension = '.tiff'
          remote_file.temp_path = get_tiff_file
        elsif extension == KnowingsApi::File::EXTENSION
          remote_file.remotable = self
          remote_file.extension = '.kzip'
          remote_file.temp_path = get_kzip_file
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
      elsif service_name == 'Knowings'
        if preseizures.any? || !is_awaiting_pre_assignment
          current_remote_files << get_remote_file(object, service_name, KnowingsApi::File::EXTENSION)
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
