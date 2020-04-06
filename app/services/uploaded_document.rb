# -*- encoding : UTF-8 -*-
# Handler for incoming documents. Used for web uploads and dropbox imports
class UploadedDocument
  attr_reader :file, :original_file_name, :user, :code, :journal, :prev_period_offset, :errors, :temp_document


  VALID_EXTENSION = %w(.pdf .jpeg .jpg .png .bmp .tiff .tif .heic).freeze


  def self.valid_extensions
    VALID_EXTENSION.join(' ')
  end


  def initialize(file, original_file_name, user, journal, prev_period_offset, uploader = nil, api_name=nil, analytic=nil)
    @file     = file
    @user     = user
    @code     = @user.code
    @journal  = journal
    @api_name = api_name
    @uploader = uploader || user

    @original_file_name  = original_file_name.gsub(/\0/, '')
    @prev_period_offset  = prev_period_offset.to_i

    @errors = []

    @errors << [:invalid_period, period: period]     unless valid_prev_period_offset?
    @errors << [:journal_unknown, journal: @journal] unless valid_journal?
    @errors << [:invalid_file_extension, extension: extension, valid_extensions: UploadedDocument.valid_extensions] unless valid_extension?

    if @errors.empty?
      begin
        unless File.exist?(@file.path) && DocumentTools.modifiable?(processed_file.path)
          @errors << [:file_is_corrupted_or_protected, nil]
        end
      rescue => e
        LogService.info('document_upload', "[Upload error] #{@file.path} - file corrupted - #{e.to_s}")
        @errors << [:file_is_corrupted_or_protected, nil]
      end

      @errors << [:file_size_is_too_big, size_in_mo: size_in_mo]         unless valid_file_size?
      @errors << [:pages_number_is_too_high, pages_number: pages_number] unless valid_pages_number?
      @errors << [:already_exist, nil]                                   unless unique?

      if @errors.empty?
        analytic_validator = IbizaAnalytic::Validator.new(@user, analytic)
        @errors << [:invalid_analytic_params, nil]                         unless analytic_validator.valid_analytic_presence?
        @errors << [:invalid_analytic_ventilation, nil]                    unless analytic_validator.valid_analytic_ventilation?
      end
    end

    if @errors.empty?
      pack = TempPack.find_or_create_by_name(pack_name) # Create pack to host the temp document
      LogService.info('document_upload', "[Temp_pack - #{api_name}] #{pack.name} - #{TempPack.where(name: pack.name).size} found - temp_pack")

      pack.update_pack_state # Create or update pack related to temp_pack
      LogService.info('document_upload', "[Pack - #{api_name}] #{pack.name} - #{Pack.where(name: pack.name).size} found - pack")

      options = {
        delivered_by:          @uploader.code,
        delivery_type:         'upload',
        api_name:              api_name,
        original_file_name:    @original_file_name,
        is_content_file_valid: true,
        original_fingerprint:  fingerprint,
        analytic:              analytic_validator.analytic_params_present? ? analytic : nil
      }

      @temp_document = AddTempDocumentToTempPack.execute(pack, processed_file, options) # Create temp document for temp pack
    end

    clean_tmp
  end


  def valid?
    @errors.empty?
  end


  def invalid?
    !valid?
  end

  def already_exist?
    @errors.detect { |e| e.first == :already_exist }.present?
  end

  def full_error_messages
    results = []

    @errors.each do |error|
      results << I18n.t("activerecord.errors.models.uploaded_document.attributes.#{error.first}", error.last)
    end

    results.join(', ')
  end


  def file_name
    "#{@code}_#{@journal}_#{period}.pdf"
  end

  private

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
          LogService.info('document_upload', "[Upload error] #{@file.path} - attempt to recreate")
          re_create_pdf @file.path, file_path
          if !DocumentTools.modifiable?(file_path)
            LogService.info('document_upload', "[Upload error] #{@file.path} - force correction")
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
          api_name: @api_name,
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


  def extension
    File.extname(@original_file_name).downcase
  end


  def valid_extension?
    extension.in? VALID_EXTENSION
  end


  def period
    @period ||= Period.period_name(period_service.period_duration, @prev_period_offset)
  end


  def pack_name
    DocumentTools.pack_name(file_name)
  end


  def valid_journal?
    @user.account_book_types.where(name: @journal).first.present?
  end


  def period_service
    @period_service ||= PeriodService.new user: @user
  end


  def valid_prev_period_offset?
    if @prev_period_offset.in? 0..period_service.authd_prev_period
      if @prev_period_offset == 0
        true
      else
        if period_service.prev_expires_at
          period_service.prev_expires_at > Time.now
        else
          true
        end
      end
    else
      false
    end
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
    @file.size <= 1_000_000_000
  end


  def size_in_mo
    '%0.2f' % (@file.size / 1_000_000.0)
  end

  def unique?
    TempDocument.where('user_id = ? AND (original_fingerprint = ? OR content_fingerprint = ? OR raw_content_fingerprint = ?)', @user.id, fingerprint, fingerprint, fingerprint).first ? false : true
  end

  def fingerprint
    @fingerprint ||= DocumentTools.checksum(@file.path)
  end
end
