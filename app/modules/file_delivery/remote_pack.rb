module FileDelivery::RemotePack
  def init_delivery_for(object, options)
    init_delivery(object, options)
  end


  def init_delivery(object, options)
    type  = options[:type]
    force = options[:force]
    current_remote_files = []

    if object.class.name == User.name
      services_name = object.find_or_create_external_file_storage.active_services_name
    elsif object.class.name == Organization.name
      services_name = ['Knowings']
    else
      services_name = ['Dropbox Extended']
    end

    services_name.each do |service_name|
      # original
      if type.in? [FileDelivery::RemoteFile::ALL, FileDelivery::RemoteFile::ORIGINAL_ONLY]
        document = original_document
        document.extend FileDelivery::RemoteFile

        temp_remote_files = document.get_remote_files(object, service_name)
        temp_remote_files.each(&:waiting!)

        current_remote_files += temp_remote_files
      end
      # pieces
      if type.in? [FileDelivery::RemoteFile::ALL, FileDelivery::RemoteFile::PIECES_ONLY]
        is_custom_name_active = organization.foc_file_naming_policy.scope == 'organization' || object.class.in?([Organization, Group]) || object.is_prescriber
        is_custom_name_needed = is_custom_name_active && organization.foc_file_naming_policy.pre_assignment_needed?

        pieces.each do |piece|
          next if piece.is_awaiting_pre_assignment && is_custom_name_needed
          piece.extend FileDelivery::RemoteFile

          temp_remote_files = piece.get_remote_files(object, service_name)
          temp_remote_files.each(&:waiting!) if force

          current_remote_files += temp_remote_files
        end
      end
      # report
      next unless type == FileDelivery::RemoteFile::REPORT && reports.any?

      reports.order(created_at: :asc).each do |report|
        report.extend FileDelivery::RemoteReport

        current_remote_files += report.get_remote_files(object, service_name, force)
      end
    end

    current_remote_files
  end
end
