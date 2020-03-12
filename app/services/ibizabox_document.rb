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
        if DocumentTools.protected?(@file.path)
          DocumentTools.remove_pdf_security(@file.path, file_path)
          unless File.exist?(file_path) && DocumentTools.modifiable?(file_path)
            FileUtils.cp @file.path, file_path
          end
        else
          FileUtils.cp @file.path, file_path
        end
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

end
