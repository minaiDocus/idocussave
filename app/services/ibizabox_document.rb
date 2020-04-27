# -*- encoding : UTF-8 -*-
class IbizaboxDocument
  attr_reader :temp_document

  def initialize(file, folder, document_id, prev_period_offset)
    @folder             = folder
    @user               = folder.user
    @journal            = folder.journal
    @file               = file
    @document_id        = document_id
    @prev_period_offset = prev_period_offset

    if valid?
      pack = TempPack.find_or_create_by_name pack_name
      options = {
        original_file_name:     File.basename(@file),
        delivered_by:           'ibiza',
        delivery_type:          'upload',
        user_id:                @user.id,
        api_id:                 document_id,
        api_name:               'ibiza',
        is_content_file_valid:  true,
        wait_selection:         @folder.is_selection_needed
      }
      @temp_document = AddTempDocumentToTempPack.execute(pack, processed_file, options)
      @folder.temp_documents << @temp_document
    end
    clean_tmp
  end

  def file_name
    "#{@user.code}_#{@journal.name}_#{period}.pdf"
  end

  def pack_name
    DocumentTools.pack_name file_name
  end

private

  def valid?
    @valid ||= valid_extension? && valid_pages_number? && valid_file_size? && DocumentTools.modifiable?(processed_file.path)
  end

  def valid_extension?
    UploadedDocument.valid_extensions.include?(extension)
  end

  def valid_pages_number?
    pages_number <= 100
  end

  def pages_number
    DocumentTools.pages_number(@file.path)
  rescue
    0
  end

  def valid_file_size?
    @file.size > 0 && @file.size <= 1_000_000_000
  end

  def period_service
    @period_service ||= PeriodService.new user: @user
  end

  def period
    @period ||= Period.period_name period_service.period_duration, @prev_period_offset
  end

  def extension
    File.extname(@file.path).downcase
  end

  def processed_file
    if @temp_file
      @temp_file
    else
      @dir = Dir.mktmpdir

      file_path = File.join(@dir, file_name)

      if extension == '.pdf'
        _file = @file.path

        if DocumentTools.protected?(@file.path)
          safe_file = file_path.gsub('.pdf', '_safe.pdf')
          DocumentTools.remove_pdf_security(@file.path, safe_file)
          _file = safe_file
        end

        if File.exist?(_file) && DocumentTools.modifiable?(_file)
          FileUtils.cp _file, file_path
        else
          re_create_pdf @file.path, file_path
          if !DocumentTools.modifiable?(file_path)
            force_correct_pdf(@file.path, file_path)
          end
        end
      else
        DocumentTools.to_pdf(@file.path, file_path, @dir)
      end

      @temp_file = File.open(file_path, 'r')
    end
  end

  def re_create_pdf(source, destination)
    _tmp_file = Tempfile.new('tmp_pdf').path
    success = DocumentTools.to_pdf_hight_quality source, _tmp_file

    success ? FileUtils.cp(_tmp_file, destination) : FileUtils.cp(source, destination)

    File.unlink _tmp_file
  end

  def force_correct_pdf(source, destination)
    correction_data = DocumentTools.force_correct_pdf(source)
    FileUtils.cp correction_data[:output_file], destination

    log_document = {
        name: "Account::Documents::UploadsController",
        erreur_type: "File corrupted, forcing to correct ...",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          api_name: 'ibiza',
          code: @code,
          journal: @journal,
          period: @prev_period_offset,
          file_corrupted: @file.path,
          file_corrected: correction_data[:output_file],
          corrected: correction_data[:corrected],
          correction_errors: correction_data[:errors]
        }
      }

      begin
        ErrorScriptMailer.error_notification(log_document, { attachements: [{name: @original_file_name, file: File.read(@file.path)}] } ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document).deliver
      end
  end

  def clean_tmp
    @temp_file.close if @temp_file
    FileUtils.remove_entry @dir if @dir
  end

end
