module FileDelivery::RemoteFile
  ALL           = 0
  REPORT        = 3
  PIECES_ONLY   = 2
  ORIGINAL_ONLY = 1


  def kzip_options
    user = pack.owner
    knowings = user.organization.knowings

    _preseizures = preseizures
    _preseizures = [nil] unless _preseizures.any?

    _preseizures.map do |preseizure|
      period = if preseizure
                 preseizure.date.to_date
               else
                 DocumentTools.to_period(name)
               end

      exercise = IbizaLib::ExerciseFinder.new(user, period, user.organization.ibiza).execute

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
      options[:file_name]       = DocumentTools.file_name name

      options.with_indifferent_access
    end
  end


  def get_kzip_file
    pole_name = pack.owner.try(:organization).try(:knowings).try(:pole_name)
    return nil unless File.exist?(cloud_content_object.path.to_s)

    KnowingsApi::File.create(cloud_content_object.path, pole_name: pole_name, data: kzip_options)
  end


  def get_remote_file(object, service_name, extension = '.pdf')
    remote_file = remote_files.of(object, service_name).with_extension(extension).first

    mcf_passed = (service_name == 'My Company Files' && user.mcf_storage.nil?) ? false : true

    if remote_file.nil? && mcf_passed
      remote_file              = RemoteFile.new
      remote_file.receiver     = object
      remote_file.pack         = self.is_a?(Pack) ? self : pack #remote file can be document or pack itself
      remote_file.service_name = service_name
      remote_file.remotable    = self

      if extension == KnowingsApi::File::EXTENSION
        remote_file.extension = '.kzip'
        remote_file.temp_path = get_kzip_file.to_s
      end

      remote_file.save
    end

    return nil if extension == KnowingsApi::File::EXTENSION && !remote_file.temp_path.present?

    remote_file
  end


  def get_remote_files(object, service_name)
    current_remote_files = []

    if service_name == 'Knowings'
      if preseizures.any? || !is_awaiting_pre_assignment?
        current_remote_files << get_remote_file(object, service_name, KnowingsApi::File::EXTENSION)
      end
    else
      current_remote_files << get_remote_file(object, service_name)
    end

    current_remote_files.compact
  end
end
