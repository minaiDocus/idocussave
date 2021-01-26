# -*- encoding : UTF-8 -*-
class Ibizabox::Document
  attr_reader :temp_document

  def initialize(file, folder, document_id, prev_period_offset)
    @folder             = folder
    @user               = folder.user
    @journal            = folder.journal
    @file               = file
    @document_id        = document_id
    @prev_period_offset = prev_period_offset

    CustomUtils.mktmpdir('ibizabox_document') do |dir|
      @dir            = dir
      file_path       = File.join(@dir, file_name)
      @processed_file = PdfIntegrator.new(@file, file_path, 'ibiza').processed_file

      if valid?
        temp_pack = TempPack.find_or_create_by_name pack_name

        options = {
          original_file_name:     File.basename(@file),
          delivered_by:           'ibiza',
          delivery_type:          'upload',
          user_id:                @user.id,
          api_id:                 document_id,
          api_name:               'ibiza',
          original_fingerprint:   fingerprint,
          is_content_file_valid:  true,
          wait_selection:         @folder.is_selection_needed
        }
        @temp_document = AddTempDocumentToTempPack.execute(temp_pack, @processed_file, options)
        @folder.temp_documents << @temp_document
      end
    end
  end

  def file_name
    "#{@user.code}_#{@journal.name}_#{period}.pdf"
  end

  def pack_name
    DocumentTools.pack_name file_name
  end

private

  def valid?
    @valid ||= unique? && valid_extension? && valid_pages_number? && valid_file_size? && DocumentTools.modifiable?(@processed_file.path)
  end

  def unique?
    TempDocument.where('user_id = ? AND (original_fingerprint = ? OR content_fingerprint = ? OR raw_content_fingerprint = ?)', @user.id, fingerprint, fingerprint, fingerprint).first ? false : true
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
    @period_service ||= Billing::Period.new user: @user
  end

  def period
    @period ||= Period.period_name period_service.period_duration, @prev_period_offset
  end

  def extension
    File.extname(@file.path).downcase
  end

  def fingerprint
    @fingerprint ||= DocumentTools.checksum(@file.path)
  end
end
