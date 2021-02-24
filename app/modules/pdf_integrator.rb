class PdfIntegrator
  def initialize(file, file_path, api='')
    @file      = file
    @file_path = file_path
    @api       = api
  end

  def processed_file
    if extension == '.pdf'
      _file = @file.path

      if DocumentTools.protected?(@file.path)
        safe_file = @file_path.gsub('.pdf', '_safe.pdf')
        DocumentTools.remove_pdf_security(@file.path, safe_file)
        _file = safe_file
      end

      if File.exist?(_file) && DocumentTools.modifiable?(_file)
        FileUtils.cp _file, @file_path
      else
        System::Log.info('document_upload', "[Upload error] #{@file.path} - attempt to recreate")
        re_create_pdf @file.path, @file_path
        if !DocumentTools.modifiable?(@file_path)
          System::Log.info('document_upload', "[Upload error] #{@file.path} - force correction")
          force_correct_pdf(@file.path, @file_path)
        end
      end
    else
      DocumentTools.to_pdf(@file.path, @file_path)
    end

    @file_path = Rails.root.join('spec/support/files/corrupted.pdf') unless File.exist?(@file_path) #Set a corrpted file if @file_path had not been generated
    temp_file = File.open(@file_path, 'r')
  end

  private

  def extension
    File.extname(@file.path).downcase
  end

  def re_create_pdf(source, destination)
    _tmp_file = Tempfile.new('tmp_pdf').path
    success   = DocumentTools.to_pdf_hight_quality source, _tmp_file

    success ? FileUtils.cp(_tmp_file, destination) : FileUtils.cp(source, destination)

    File.unlink _tmp_file
  end

  def force_correct_pdf(source, destination)
    correction_data = DocumentTools.force_correct_pdf(source)

    FileUtils.cp correction_data[:output_file], destination

    log_document = {
      subject: "[PdfIntegrator] file corrupted, forcing to correct",
      name: "PdfIntegrator",
      error_group: "[pdf-integrator] file corrupted ==> forcing to correct",
      erreur_type: "File corrupted, forcing to correct ...",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        api_name: @api,
        file_path: @file_path,
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
end