# -*- encoding : UTF-8 -*-
class RetrievedDocument
  attr_reader :temp_document

  def initialize(retriever, document, temp_file_path)
    @retriever      = retriever
    @user           = retriever.user
    @journal        = retriever.journal
    @document       = document
    @temp_file_path = temp_file_path

    if valid?
      pack = TempPack.find_or_create_by_name pack_name
      options = {
        original_file_name:     "#{document['number']}.pdf",
        delivered_by:           'budgea',
        delivery_type:          'retriever',
        fingerprint:            fingerprint,
        user_id:                @user.id,
        api_id:                 document['id'],
        api_name:               'budgea',
        retriever_service_name: retriever.service_name,
        retriever_name:         retriever.name,
        retrieved_metadata:     document,
        metadata:               formatted_metadata,
        is_content_file_valid:  true,
        wait_selection:         waiting_selection?
      }
      @temp_document = AddTempDocumentToTempPack.execute(pack, file, options)
      retriever.temp_documents << @temp_document
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
    @valid ||= valid_extension? && DocumentTools.modifiable?(@temp_file_path)
  end

  def valid_extension?
    File.extname(@document['url'].to_s) == '.pdf'
  end

  def invalid?
    !valid?
  end

  def period_service
    @period_service ||= PeriodService.new user: @user
  end

  def period
    @period ||= Period.period_name period_service.period_duration, 0
  end

  def file
    if @file
      @file
    else
      @dir = Dir.mktmpdir
      file_path = File.join(@dir, file_name)
      FileUtils.cp @temp_file_path, file_path
      @file = File.open(file_path, 'r')
    end
  end

  def clean_tmp
    @file.close if @file
    FileUtils.remove_entry @dir if @dir
  end

  def fingerprint
    `md5sum #{@temp_file_path}`.split.first
  end

  def formatted_metadata
    if @metadata
      @metadata
    else
      @metadata = {}
      @metadata['date']   = Date.parse @document['date'] rescue nil
      @metadata['name']   = @document['number']          rescue nil
      @metadata['amount'] = @document['total_amount']    rescue nil
      @metadata
    end
  end

  def waiting_selection?
    if @retriever.is_selection_needed
      true
    else
      Time.parse(@document['timestamp']) < 2.months.ago
    end
  end
end
