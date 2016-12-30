# -*- encoding : UTF-8 -*-
# Handler for incoming documents. Used for web uploads and dropbox imports
class UploadedDocument
  attr_reader :file, :original_file_name, :user, :code, :journal, :prev_period_offset, :errors, :temp_document


  VALID_EXTENSION = %w(.pdf .jpeg .jpg .gif .png .bmp .tiff .tif).freeze


  def self.valid_extensions
    VALID_EXTENSION.join(' ')
  end


  def initialize(file, original_file_name, user, journal, prev_period_offset, uploader = nil)
    @file     = file
    @user     = user
    @code     = @user.code
    @journal  = journal
    @uploader = uploader || user

    @original_file_name  = original_file_name.gsub(/\0/, '')
    @prev_period_offset  = prev_period_offset.to_i

    @errors = []

    @errors << [:invalid_period, period: period]     unless valid_prev_period_offset?
    @errors << [:journal_unknown, journal: @journal] unless valid_journal?
    @errors << [:invalid_file_extension, extension: extension, valid_extensions: UploadedDocument.valid_extensions] unless valid_extension?

    if @errors.empty?
      @errors << [:file_is_corrupted_or_protected, nil]                  unless File.exist?(@file.path) && DocumentTools.modifiable?(processed_file.path)
      @errors << [:file_size_is_too_big, size_in_mo: size_in_mo]         unless valid_file_size?
      @errors << [:pages_number_is_too_high, pages_number: pages_number] unless valid_pages_number?
      @errors << [:already_exist, nil]                                   unless unique?
    end

    if @errors.empty?
      pack = TempPack.find_or_create_by_name(pack_name) # Create pack to host the temp document

      pack.update_pack_state # Create or update pack related to temp_pack

      options = {
        delivered_by:  @uploader.code,
        delivery_type: 'upload',
        original_file_name:    @original_file_name,
        is_content_file_valid: true
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
        FileUtils.cp @file.path, file_path
      else
        DocumentTools.to_pdf(@file.path, file_path)
      end

      @temp_file = File.open(file_path, 'r')
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
    @file.size <= 10_000_000
  end


  def size_in_mo
    '%0.2f' % (@file.size / 1_000_000.0)
  end

  def unique?
    temp_pack = TempPack.where(name: pack_name).first
    temp_pack && temp_pack.temp_documents.where(content_fingerprint: fingerprint).first ? false : true
  end

  def fingerprint
    DocumentTools.checksum(processed_file.path)
  end
end
