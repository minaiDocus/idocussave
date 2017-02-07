module AccountingWorkflow::OcrProcessing
  class << self
    def send_document(temp_document_id)
      temp_document = TempDocument.find_by_id(temp_document_id)
      if temp_document && temp_document.ocr_needed?
        filepath = FileStoragePathUtils.path_for_object(temp_document)
        FileUtils.cp filepath, input_path.join(temp_document.file_name_with_position)
      end
    end

    def fetch
      valid_temp_documents.each do |temp_document, file_path|
        temp_document.with_lock do
          if temp_document.ocr_needed? && File.exists?(file_path)
            temp_document.raw_content           = File.open(temp_document.content.path)

            dir                                 = Dir.mktmpdir
            temp_document_file_path             = File.join(dir, temp_document.content_file_name)
            FileUtils.cp file_path, temp_document_file_path

            temp_document.content               = File.open(temp_document_file_path)
            temp_document.is_ocr_layer_applied  = true

            # INFO : Blank pages are removed, so we need to reassign pages_number
            temp_document.pages_number = DocumentTools.pages_number file_path

            temp_document.save

            if temp_document.pages_number > 2 && temp_document.temp_pack.is_bundle_needed?
              temp_document.bundle_needed
            else
              temp_document.ready
            end
            clean_tmp dir
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
      FileUtils.mkdir_p error_path
      errors.each do |error|
        FileUtils.mv error[:file_path], error_path
        logger.error error[:error]
      end
    end

    def move_to_archive(file_path)
      path = archive_path.join Time.now.strftime('%Y-%m-%d')
      FileUtils.mkdir_p path
      FileUtils.mv file_path, path if file_path
    end
  end
end
