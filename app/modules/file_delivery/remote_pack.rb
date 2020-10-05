module FileDelivery::RemotePack
  def init_delivery_for(object, options)
    init_delivery(object, options)
  end


  def init_delivery(object, options)
    type  = options[:type]
    force = options[:force]
    current_remote_files = []

    service_names = if object.class == User
                      object.find_or_create_external_file_storage.active_services_name
                    elsif object.class == Organization
                      organization_services = []
                      unless type == FileDelivery::RemoteFile::REPORT
                        organization_services << 'Knowings'         if object.try(:knowings).try(:ready?)
                        organization_services << 'My Company Files' if object.try(:mcf_settings).try(:ready?)
                      end
                      organization_services << 'FTP' if object.try(:ftp).try(:configured?)
                      organization_services
                    else
                      ['Dropbox Extended']
                    end

    service_names.each do |service_name|
      # original
      if type.in?([FileDelivery::RemoteFile::ALL, FileDelivery::RemoteFile::ORIGINAL_ONLY]) && !service_name.in?(['Knowings', 'My Company Files'])
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
          next if is_custom_name_needed && (piece.is_awaiting_pre_assignment? || piece.preseizures.select(&:is_not_blocked_for_duplication).empty?)
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
