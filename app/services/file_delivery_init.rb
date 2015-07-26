# -*- encoding : UTF-8 -*-
class FileDeliveryInit
  def self.prepare(object, options={})
    if object.class != Pack::Report || !object.organization.try(:ibiza).try(:is_configured?)
      options = { type: RemoteFile::ALL, force: false, delay: false }.merge(options).with_indifferent_access
      if object.class == Pack
        pack = object
      elsif object.class == Pack::Report
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
          is_custom_name_active = organization.foc_file_naming_policy.scope == 'organization' || object.class.in?([Organization, Group]) || object.is_prescriber
          is_custom_name_needed = is_custom_name_active && organization.foc_file_naming_policy.pre_assignment_needed?
          pieces.each do |piece|
            unless piece.is_awaiting_pre_assignment && is_custom_name_needed
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
        end
        # report
        if type == RemoteFile::REPORT && reports.any?
          reports.asc(:created_at).each do |report|
            report.extend FileDeliveryInit::RemoteReport
            current_remote_files += report.get_remote_files(object, service_name, force)
          end
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
      dir = Dir.mktmpdir('tiff_')
      temp_path = "#{dir}/#{self.content_file_name.sub(/\.pdf\z/,'.tiff')}"
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
        exercise = FindExercise.new(user, period, user.organization.ibiza).execute
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
        if exercise
          options[:exercise]      = true
          options[:start_time]    = exercise.start_date.to_time
          options[:end_time]      = exercise.end_date.to_time
        else
          options[:exercise]      = false
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
      pole_name = pack.owner.try(:organization).try(:knowings).try(:pole_name)
      KnowingsApi::File.create(self.content.path, pole_name: pole_name, data: kzip_options)
    end

    def get_remote_file(object, service_name, extension='.pdf')
      remote_file = remote_files.of(object, service_name).with_extension(extension).first
      if remote_file.nil?
        remote_file              = ::RemoteFile.new
        remote_file.receiver     = object
        remote_file.pack         = self.pack
        remote_file.service_name = service_name
        remote_file.remotable = self
        if extension == '.tiff'
          remote_file.extension = '.tiff'
          remote_file.temp_path = get_tiff_file
        elsif extension == KnowingsApi::File::EXTENSION
          remote_file.extension = '.kzip'
          remote_file.temp_path = get_kzip_file
        end
        remote_file.save
      elsif remote_file.temp_path.match(/_all.tiff/)
        remote_file.temp_path = get_tiff_file
        remote_file.save
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
    def get_remote_files(receiver, service_name, force=false)
      if type != 'NDF'
        not_delivered = not_delivered_preseizures(receiver, service_name, force)
        if not_delivered.size > 0
          remote_file = ::RemoteFile.new
          remote_file.receiver     = receiver
          remote_file.remotable    = self
          remote_file.pack         = pack
          remote_file.service_name = service_name
          remote_file.temp_path    = generate_csv_files(receiver, service_name, not_delivered)
          remote_file.preseizures  = not_delivered
          remote_file.save
          [remote_file]
        else
          []
        end
      else
        []
      end
    end

    def not_delivered_preseizures(receiver, service_name, force=false)
      not_delivered = []
      if force
        not_delivered = preseizures.by_position
      else
        delivered_preseizure_ids = remote_files.of(receiver, service_name).
          where(temp_path: /\.csv/).
          distinct(:preseizure_ids).
          flatten.
          uniq
        not_delivered = preseizures.where(:_id.nin => delivered_preseizure_ids).by_position
      end
      not_delivered
    end

    def csv_delivery_number(receiver, service_name)
      pack.remote_files.of(receiver, service_name).where(temp_path: /\.csv/).size + 1
    end

    def generate_csv_files(receiver, service_name, pres=preseizures)
      number = csv_delivery_number(receiver, service_name)
      data = PreseizuresToCsv.new(user, pres).execute
      basename = "#{name.gsub(' ', '_')}-L#{number}"
      dir = Dir.mktmpdir("#{basename}__")
      file_path = File.join(dir, "#{basename}.csv")
      File.write(file_path, data)
      file_path
    end
  end
end
