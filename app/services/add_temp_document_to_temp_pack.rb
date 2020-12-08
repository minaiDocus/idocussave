class AddTempDocumentToTempPack
  def self.execute(temp_pack, file, options = {})
    
    user         = temp_pack.user
    organization = temp_pack.organization

    if options[:dematbox_doc_id].present?
      opts = { dematbox_doc_id: options[:dematbox_doc_id] }

      temp_document = TempDocument.find_or_initialize_with(opts)
    elsif options[:fingerprint].present?
      opts = { original_fingerprint: options[:fingerprint], user_id: options[:user_id] }

      temp_document = TempDocument.find_or_initialize_with(opts)
    else
      temp_document ||= TempDocument.new
    end

    if options[:delivery_type] != 'retriever' || !temp_document.persisted?

      temp_document.user                 = user
      # temp_document.content            = file
      temp_document.content_file_name    = File.basename(file.path).gsub('.pdf', '')
      temp_document.original_fingerprint = options[:original_fingerprint] if options[:original_fingerprint] && organization.code != 'MCN'
      temp_document.position             = temp_pack.next_document_position unless temp_document.position
      temp_document.temp_pack            = temp_pack
      temp_document.organization         = organization
      temp_document.original_file_name   = options[:original_file_name]

      temp_document.delivered_by        = options[:delivered_by]
      temp_document.delivery_type       = options[:delivery_type]

      temp_document.dematbox_text       = options[:dematbox_text]       if options[:dematbox_text]
      temp_document.dematbox_box_id     = options[:dematbox_box_id]     if options[:dematbox_box_id]
      temp_document.dematbox_service_id = options[:dematbox_service_id] if options[:dematbox_service_id]

      temp_document.api_id                 = options[:api_id]                 if options[:api_id]
      temp_document.api_name               = options[:api_name]               if options[:api_name]
      temp_document.metadata               = options[:metadata]               if options[:metadata]
      temp_document.retrieved_metadata     = options[:retrieved_metadata]     if options[:retrieved_metadata]
      temp_document.retriever_service_name = options[:retriever_service_name] if options[:retriever_service_name]
      temp_document.retriever_name         = options[:retriever_name]         if options[:retriever_name]

      temp_document.cloud_content_object.attach(File.open(file.path), File.basename(file.path)) if temp_document.save

      if user.uses_ibiza_analytics?
        if options[:analytic].present?
          IbizaLib::Analytic.add_analytic_to_temp_document options[:analytic], temp_document
        elsif temp_pack.journal && temp_pack.journal.analytic_reference.present?
          temp_document.analytic_reference = temp_pack.journal.analytic_reference
          temp_document.save
        end
      end

      if temp_document.metadata.present?
        metadata2 = temp_document.metadata2 || temp_document.build_metadata2
        metadata2.date   = temp_document.metadata['date']
        metadata2.name   = temp_document.metadata['name'][0..190]
        if temp_document.metadata['amount'].present?
          metadata2.amount = temp_document.metadata['amount'] < 100_000_000 ? temp_document.metadata['amount'] : nil
        end
        metadata2.save
      end

      if options[:is_content_file_valid]
        temp_document.pages_number = DocumentTools.pages_number(temp_document.cloud_content_object.path)

        if temp_document.save
          if temp_document.retrieved?
            if options[:wait_selection]
              temp_document.wait_selection
            else
              DocumentTools.gs_error_found?(temp_document.cloud_content_object.path) ? temp_document.ready : temp_document.ocr_needed
            end
          else
            #   temp_document_params = {temp_document: temp_document, sender: User.find_by_code(temp_document.delivered_by), user: temp_document.user}
            if temp_document.from_ibizabox? && options[:wait_selection]
              temp_document.wait_selection
            # elsif DocumentTools.need_ocr?(temp_document.cloud_content_object.path)
            #   temp_document.ocr_needed
            #   Notifications::Documents.new(temp_document_params).notify_document_being_processed
            # elsif temp_document.is_bundle_needed?
            #  temp_document.bundle_needed
            # Notifications::Documents.new(temp_document_params).notify_document_being_processed
            else
              #Temp modification : replace ready state to ocr_needed
              if temp_document.api_name == 'jefacture'
                temp_document.ready
              else
                if DocumentTools.gs_error_found?(temp_document.cloud_content_object.path)
                  temp_document.is_bundle_needed? ? temp_document.bundle_needed : temp_document.ready
                else
                  temp_document.ocr_needed
                end
              end
            end
          end
        else
          log_document = {
            subject: "[AddTempDocumentToTempPack] temp document not saved",
            name: "AddTempDocumentToTempPack",
            error_group: "[add-temp-document-to-temp-pack] temp document not saved",
            erreur_type: "Temp Document not saved",
            date_erreur: Time.now.strftime('%Y-%M-%d %H:%M:%S'),
            more_information: {
              error_message: temp_document.try(:errors).try(:messages).to_s,
              model: temp_document.inspect,
              user: temp_document.user.inspect
            }
          }

          ErrorScriptMailer.error_notification(log_document).deliver
        end
      else
        temp_document.original_fingerprint = nil
        temp_document.unreadable

        temp_document.save
      end

      temp_pack.save
    end

    AccountingPlan::IbizaUpdateWorker.perform_async user.id       if user.accounting_plan.try(:need_update?) && user.uses?(:ibiza)
    AccountingPlan::ExactOnlineUpdateWorker.perform_async user.id if user.accounting_plan.try(:need_update?) && user.uses?(:exact_online)

    temp_document
  end
end
