module AccountingWorkflow::OcrProcessing
  class << self
    def send_document(temp_document_id, retry_count=0)
      temp_document = TempDocument.find_by_id(temp_document_id)
      if temp_document && temp_document.ocr_needed?
        begin
          FileUtils.cp temp_document.cloud_content_object.path, input_path.join(temp_document.file_name_with_position)
          AccountingWorkflow::OcrProcessing.delay_for(2.hours, queue: :low).release_document(temp_document.id)
        rescue => e
          if retry_count < 3
            AccountingWorkflow::OcrProcessing.delay_for(30.minutes, queue: :low).send_document(temp_document.id, (retry_count+1))
          else
            log_document = {
              subject: "[AccountingWorkflow::OcrProcessing] can't send temp document to ocr #{e.message}",
              name: "OcrProcessing",
              error_group: "[OcrProcessing] sending temp doc to ocr",
              erreur_type: "Can't send temp doc to ocr : #{temp_document.original_file_name.to_s}",
              date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
              more_information: {
                retry_count: retry_count,
                temp_document: temp_document.inspect,
                error_message: e.to_s
              }
            }

            ErrorScriptMailer.error_notification(log_document).deliver
          end
        end
      end
    end

    #This function is used to unlock a blocked ocr_needed document
    def release_document(temp_document_id)
      temp_document = TempDocument.find temp_document_id
      return false unless temp_document.ocr_needed?

      temp_document.with_lock do
        if temp_document.is_bundle_needed?
          temp_document.bundle_needed
        else
          temp_document.ready
        end
      end

      log_document = {
        subject: "[AccountingWorkflow::OcrProcessing] an ocr pending document has been released #{temp_document.original_file_name.to_s}",
        name: "OcrProcessing",
        error_group: "[OcrProcessing] unlock blocked ocr_needed document",
        erreur_type: "An ocr pending document has been released : #{temp_document.original_file_name.to_s}",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          temp_document: temp_document.inspect,
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end

    def fetch
      valid_temp_documents.each do |temp_document, file_path|
        temp_document.with_lock do
          if temp_document.ocr_needed? && File.exists?(file_path)
            # temp_document.raw_content           = File.open(temp_document.cloud_content_object.path)

            CustomUtils.mktmpdir('ocr_processing') do |dir|
              temp_document_file_path             = File.join(dir, temp_document.cloud_content_object.filename)
              FileUtils.cp file_path, temp_document_file_path

              # temp_document.content               = File.open(temp_document_file_path)
              temp_document.is_ocr_layer_applied  = true

              # INFO : Blank pages are removed, so we need to reassign pages_number
              temp_document.pages_number = DocumentTools.pages_number file_path

              content_file = temp_document.cloud_content_object
              temp_document.cloud_raw_content_object.attach(File.open(content_file.path), File.basename(content_file.path)) if temp_document.save
              temp_document.cloud_content_object.attach(File.open(temp_document_file_path), File.basename(temp_document_file_path))

              if temp_document.is_bundle_needed?
                temp_document.bundle_needed
              else
                temp_document.ready
              end
            end

            move_to_archive file_path
          end
        end
      end
    end

    def position(file_path)
      File.basename(file_path, '.pdf').split('_')[-1].to_i
    end

    def clean_tmp(dir)
      FileUtils.remove_entry dir if dir
    end

    def ready_files_path
      Dir.glob(output_path.join('*.pdf')).select do |file_path|
        File.atime(file_path) < 1.minute.ago
      end
    end

    def grouped_files_path
      ready_files_path.group_by do |file_path|
        basename = File.basename(file_path, '.pdf').split('_')
        basename.size == 5 ? basename[0..-2].join(' ').sub(' ','%') : basename[0..-2].join(' ')
      end
    end

    def valid_temp_documents
      errors           = []
      valid_files      = []
      grouped_files_path.each do |temp_pack_name, files_path|
        temp_pack_name = CustomUtils.replace_code_of(temp_pack_name)

        temp_pack     = TempPack.find_by_name(temp_pack_name + ' all')
        if temp_pack
          files_path.each do |file_path|
            temp_document = temp_pack.temp_documents.find_by_position position(file_path)

            error = []
            file_name = File.basename(file_path)
            error << {file_path: file_path, error: "#{file_name} is protected or corrupted"} unless DocumentTools.modifiable? file_path
            error << {file_path: file_path, error: "#{file_name} not found"} unless temp_document
            error << {file_path: file_path, error: "#{file_name} do not need ocr"} if temp_document && !temp_document.ocr_needed?

            if error.empty?
              valid_files << [temp_document, file_path]
            else
              errors += error
            end
          end
        else
          files_path.each do |file_path|
            errors << {file_path: file_path, error: "#{temp_pack_name} all not found"}
          end
        end
      end
      move_and_log_errors(errors) if errors.any?
      valid_files
    end

    def logger
      @@logger ||= Logger.new error_path.join('ocr_processing_errors.log')
    end

    def input_path
      AccountingWorkflow.ocr_processing_dir.join 'input'
    end

    def archive_path
      AccountingWorkflow.ocr_processing_dir.join 'archives'
    end

    def output_path
      AccountingWorkflow.ocr_processing_dir.join 'output'
    end

    def error_path
      output_path.join 'errors'
    end

    def move_and_log_errors(errors)
      files = []
      FileUtils.mkdir_p error_path
      errors.each do |error|
        files <<  {name: File.basename(error[:file_path]), file: File.read(error[:file_path])}
        FileUtils.mv error[:file_path], error_path
        logger.error error[:error]
      end

      mail_infos = {
        subject: "[AccountingWorkflow::OcrProcessing] log errors found",
        name: "OcrProcessing.move_and_log_errors",
        error_group: "[OcrProcessing] log errors found",
        erreur_type: "Notifications",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          error: errors,
          error_path: error_path.to_s,
          method: 'move_and_log_errors'
        }
      }

      begin
        ErrorScriptMailer.error_notification(mail_infos, { attachements: files } ).deliver
      rescue
        ErrorScriptMailer.error_notification(mail_infos).deliver
      end
    end

    def move_to_archive(file_path)
      path = archive_path.join Time.now.strftime('%Y-%m-%d')
      FileUtils.mkdir_p path
      FileUtils.mv file_path, path if file_path
    end
  end
end
