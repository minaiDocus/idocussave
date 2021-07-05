class PdfIntegrator
  def self.verify_corruption(file_path)
    fingerprint = DocumentTools.checksum(file_path)

    corrupted_doc = Archive::DocumentCorrupted.where(fingerprint: fingerprint).first

    if corrupted_doc.try(:rejected?)
      'rejected'
    elsif corrupted_doc.try(:uploaded?)
      'uploaded'
    else
      'continu'
    end
  end

  def initialize(file, file_path, api='')
    origin_file_path = file.path
    dest_file_path   = file_path

    @file      = file
    @file_path = file_path
    @api       = api

    origin_file_path = CustomUtils.clear_string(origin_file_path)
    dest_file_path   = CustomUtils.clear_string(dest_file_path)

    if origin_file_path != file.path && File.exist?(file.path)
      begin
        FileUtils.cp file.path, origin_file_path
      rescue => e
        origin_file_path = file.path
      end
      @file = File.open(origin_file_path)
    end

    if dest_file_path != file_path && File.exist?(file_path)
      begin
        FileUtils.cp file_path, dest_file_path
      rescue
        dest_file_path = file_path
      end
      @file_path = dest_file_path
    end
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

    unless File.exist?(@file_path) #Set a corrpted file if @file_path had not been generated
      sleep 10

      begin
        size = File.size(@file_path) * 0.000001
      rescue => e
        size = e.to_s
      end

      log_document = {
        subject: "[PdfIntegrator] file corrupted, forcing to correct - after 10 sec",
        name: "PdfIntegrator",
        error_group: "[pdf-integrator] file corrupted ==> forcing to correct - after 10 sec",
        erreur_type: "File corrupted, forcing to correct ... 10 sec",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          api_name: @api,
          exist_1: "#{File.exist?(@file_path)} ==> #{@file_path}",
          exist_2: "#{File.exist?(@file.path)} ==> #{@file.path}",
          size: size
        }
      }

      ErrorScriptMailer.error_notification(log_document, { unlimited: true }).deliver if @api != 'retrieved_document' #Skip sending email when api source is from retrieved document

      @file_path = Rails.root.join('spec/support/files/corrupted.pdf') unless File.exist?(@file_path) #Set a corrpted file if @file_path had not been generated
    end

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

    begin
      size = File.size(@file_path) * 0.000001
      modifiable = DocumentTools.modifiable?(@file_path)
      modifiable_2 = DocumentTools.modifiable?(source)
    rescue => e
      size = e.to_s
      modifiable = 'false'
      modifiable_2 = 'false'
    end

    log_document = {
      subject: "[PdfIntegrator] file corrupted, forcing to correct",
      name: "PdfIntegrator",
      error_group: "[pdf-integrator] file corrupted ==> forcing to correct",
      erreur_type: "File corrupted, forcing to correct ...",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        api_name: @api,
        file_size: size,
        file_path: @file_path,
        exist: File.exist?(@file_path),
        modifiable: modifiable.to_s,
        file_corrupted: @file.path,
        checksum: DocumentTools.checksum(@file.path),
        modifiable_source: modifiable_2.to_s,
        file_corrected: correction_data[:output_file],
        corrected: correction_data[:corrected],
        correction_errors: correction_data[:errors]
      }
    }

    return true if @api == 'retrieved_document' #Skip sending email when api source is from retrieved document

    if 1 == 1 || !correction_data[:corrected]
      begin
        ErrorScriptMailer.error_notification(log_document, { unlimited: true, attachements: [{name: 'corrupted.pdf', file: File.read(@file_path)}] } ).deliver
      rescue
        ErrorScriptMailer.error_notification(log_document, { unlimited: true }).deliver
      end
    end
  end
end