class AddTempDocumentToTempPack
  def self.execute(temp_pack, file, options = {})
    user         = temp_pack.user
    organization = temp_pack.organization

    if options[:dematbox_doc_id].present?
      opts = { dematbox_doc_id: options[:dematbox_doc_id] }

      temp_document = TempDocument.find_or_initialize_with(opts)
    elsif options[:signature].present?
      opts = { signature: options[:signature], user_id: options[:user_id] }

      temp_document = TempDocument.find_or_initialize_with(opts)
    else
      temp_document ||= TempDocument.new
    end

    if options[:delivery_type] != 'fiduceo' || !temp_document.persisted?

      temp_document.user                = user
      temp_document.content             = file
      temp_document.position            = temp_pack.next_document_position unless temp_document.position
      temp_document.temp_pack           = temp_pack
      temp_document.organization        = organization
      temp_document.original_file_name  = options[:original_file_name]

      temp_document.delivered_by        = options[:delivered_by]
      temp_document.delivery_type       = options[:delivery_type]

      temp_document.dematbox_text       = options[:dematbox_text]       if options[:dematbox_text]
      temp_document.dematbox_box_id     = options[:dematbox_box_id]     if options[:dematbox_box_id]
      temp_document.dematbox_service_id = options[:dematbox_service_id] if options[:dematbox_service_id]

      temp_document.fiduceo_id                  = options[:fiduceo_id]          if options[:fiduceo_id]
      temp_document.fiduceo_metadata            = options[:fiduceo_metadata]    if options[:fiduceo_metadata]
      temp_document.fiduceo_service_name        = options[:service_name]        if options[:service_name]
      temp_document.fiduceo_custom_service_name = options[:custom_service_name] if options[:custom_service_name]

      temp_document.save

      if options[:is_content_file_valid]
        temp_document.pages_number = DocumentTools.pages_number(temp_document.content.path)

        temp_document.save

        if temp_document.fiduceo?
          options[:wait_selection] ? temp_document.wait_selection : temp_document.ready
        else
          if DematboxServiceApi.config.is_active && temp_document.uploaded? && DocumentTools.need_ocr?(temp_document.content.path)
            temp_document.ocr_needed
          elsif temp_pack.is_bundle_needed? && (temp_document.delivery_type == 'scan' || temp_document.pages_number > 2)
            temp_document.bundle_needed
          else
            temp_document.ready
          end
        end
      else
        temp_document.unreadable
      end

      temp_pack.save
    end

    temp_document
  end
end
