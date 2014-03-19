# -*- encoding : UTF-8 -*-
class UploadedDocument
  attr_reader :file, :original_file_name, :user, :code, :journal, :prev_period_offset, :errors, :temp_document

  VALID_EXTENSION = %w(.pdf .bmp .jpeg .jpg .png .tiff .tif .gif)

  def initialize(file, original_file_name, user, journal, prev_period_offset)
    @file = file
    @original_file_name = original_file_name.gsub(/\0/,'')
    @user = user
    @code = @user.code
    @journal = journal
    @prev_period_offset = prev_period_offset.to_i

    @errors = []
    @errors << [:journal_unknown, journal: @journal] unless valid_journal?
    @errors << [:invalid_period, period: period] unless valid_prev_period_offset?
    @errors << [:invalid_file_extension, extension: extension] unless valid_extension?
    @errors << [:file_size_is_too_big, size_in_mo: size_in_mo] unless valid_file_size?
    unless File.exists?(@file.path) && DocumentTools.modifiable?(processed_file.path)
      @errors << [:file_is_corrupted_or_protected, nil]
    end

    if @errors.empty?
      pack = TempPack.find_or_create_by_name pack_name
      options = {
        delivery_type: 'upload',
        delivered_by: @code,
        original_file_name: @original_file_name,
        is_content_file_valid: true
      }
      @temp_document = pack.add processed_file, options
    end
    clean_tmp
  end

  def valid?
    @errors.empty?
  end

  def invalid?
    !valid?
  end

  def full_error_messages
    results = []
    @errors.each do |error|
      results << I18n.t("mongoid.errors.models.uploaded_document.attributes.#{error.first.to_s}", error.last)
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
    @temp_file.close
    FileUtils.remove_entry @dir
  end

  def extension
    File.extname(@original_file_name).downcase
  end

  def valid_extension?
    extension.in? VALID_EXTENSION
  end

  def period
    @period ||= Scan::Period.period_name(period_service.period_duration, @prev_period_offset)
  end

  def pack_name
    DocumentTools.pack_name file_name
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

  def valid_file_size?
    @file.size <= 52428800
  end

  def size_in_mo
    "%0.2f" % (@file.size / 1048576.0)
  end
end
