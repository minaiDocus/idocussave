# -*- encoding : UTF-8 -*-
# Handler for incoming documents. Used for web uploads and dropbox imports
class UploadedDocument
  attr_reader :file, :original_file_name, :user, :code, :journal, :prev_period_offset, :errors, :temp_document, :processed_file


  VALID_EXTENSION = %w(.pdf .jpeg .jpg .png .bmp .tiff .tif .heic).freeze


  def self.valid_extensions
    VALID_EXTENSION.join(' ')
  end


  def initialize(file, original_file_name, user, journal, prev_period_offset, uploader = nil, api_name=nil, analytic=nil, api_id=nil)
    @file     = file
    @user     = user
    @code     = @user.code
    @journal  = journal
    @api_id   = api_id
    @api_name = api_name
    @uploader = uploader || user

    @original_file_name  = original_file_name.gsub(/\0/, '')
    @prev_period_offset  = prev_period_offset.to_i

    @errors = []

    @errors << [:invalid_period, period: period]     unless valid_prev_period_offset?
    @errors << [:journal_unknown, journal: @journal] unless valid_journal?
    @errors << [:invalid_file_extension, extension: extension, valid_extensions: UploadedDocument.valid_extensions] unless valid_extension?

    CustomUtils.mktmpdir('uploaded_document') do |dir|
      if @errors.empty?
        @dir            = dir
        file_path       = File.join(@dir, file_name)
        @processed_file = PdfIntegrator.new(@file, file_path, api_name).processed_file

        begin
          unless File.exist?(@file.path) && DocumentTools.modifiable?(@processed_file.path)
            @errors << [:file_is_corrupted_or_protected, nil]
          end
        rescue => e
          System::Log.info('document_upload', "[Upload error] #{@file.path} - file corrupted - #{e.to_s}")
          @errors << [:file_is_corrupted_or_protected, nil]
        end

        @errors << [:file_size_is_too_big, { size_in_mo: size_in_mo, authorized_size_mo: authorized_size_mo }] unless valid_file_size?
        @errors << [:pages_number_is_too_high, pages_number: pages_number] unless valid_pages_number?
        @errors << [:already_exist, nil]                                   unless unique?

        if @errors.empty?
          analytic_validator = IbizaLib::Analytic::Validator.new(@user, analytic)
          @errors << [:invalid_analytic_params, nil]                         unless analytic_validator.valid_analytic_presence?
          @errors << [:invalid_analytic_ventilation, nil]                    unless analytic_validator.valid_analytic_ventilation?
        end
      end

      if @errors.empty?
        temp_pack = TempPack.find_or_create_by_name(pack_name) # Create pack to host the temp document
        System::Log.info('document_upload', "[Temp_pack - #{api_name}] #{temp_pack.name} - #{TempPack.where(name: temp_pack.name).size} found - temp_pack")

        temp_pack.update_pack_state # Create or update pack related to temp_pack
        System::Log.info('document_upload', "[Pack - #{api_name}] #{temp_pack.name} - #{Pack.where(name: temp_pack.name).size} found - pack")

        options = {
          delivered_by:          @uploader.code,
          delivery_type:         'upload',
          api_id:                api_id,
          api_name:              api_name,
          original_file_name:    @original_file_name,
          is_content_file_valid: true,
          original_fingerprint:  fingerprint,
          analytic:              analytic_validator.analytic_params_present? ? analytic : nil
        }

        @temp_document = AddTempDocumentToTempPack.execute(temp_pack, @processed_file, options) # Create temp document for temp pack
      end
    end
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

  def extension
    File.extname(@file.path).downcase
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
    @period_service ||= Billing::Period.new user: @user
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
    return @pages_number if @pages_number.to_i > 0

    @pages_number = DocumentTools.pages_number(@processed_file.path)
  end

  def valid_file_size?
    File.size(@processed_file.path) <= authorized_file_size
  end

  def authorized_file_size
    return 70_000_000 if pages_number <= 0

    70_000_000 * pages_number
  end

  def authorized_size_mo
    '%0.2f' % (authorized_file_size / 1_000_000.0)
  end

  def size_in_mo
    '%0.2f' % (File.size(@file.path) / 1_000_000.0)
  end

  def unique?
    TempDocument.where('user_id = ? AND (original_fingerprint = ? OR content_fingerprint = ? OR raw_content_fingerprint = ?)', @user.id, fingerprint, fingerprint, fingerprint).first ? false : true
  end

  def fingerprint
    @fingerprint ||= DocumentTools.checksum(@file.path)
  end
end
