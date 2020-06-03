# -*- encoding : UTF-8 -*-
class RetrievedDocument
  attr_reader :temp_document

  def self.retry_get_file(retriever_id, document, count_day=0)
    retriever  = Retriever.find retriever_id
    already_exist = retriever.temp_documents.where(api_id: document['id']).first

    return false if count_day >= 3 || already_exist

    client     = Budgea::Client.new(retriever.user.budgea_account.try(:access_token))
    is_success = false

    temp_file_path = client.get_file document['id']
    dir            = Dir.mktmpdir
    file_path      = File.join(dir, 'retriever_processed_file.pdf')

    begin
      processed_file = PdfIntegrator.new(File.open(temp_file_path), file_path, 'retrieved_document').processed_file

      if client.response.status == 200
        RetrievedDocument.new(retriever, document, processed_file.path)
        retriever.update(error_message: "") if retriever.error_message.to_s.match(/Certains documents n'ont pas/)
        is_success = true
      end
    rescue => e
      error_message = e.to_s
    end

    RetrievedDocument.delay_for(24.hours).retry_get_file(retriever.id, document, (count_day+1)) if !is_success

    FileUtils.remove_entry dir

    log_document = {
      name: "RetrievedDocument",
      error_group: "[retrieved-document] retry get file from retriever",
      erreur_type: "Retry get file from retriever : #{retriever.name.to_s}",
      date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      more_information: {
        is_success: is_success,
        count_day: count_day,
        retriever: retriever.inspect,
        client: client.inspect,
        reponse_code: client.response.status.to_s,
        document: document.inspect,
        error_message: error_message.to_s,
        temp_file_path: temp_file_path.to_s
      }
    }

    ErrorScriptMailer.error_notification(log_document).deliver
  end

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
    else
      log_document = {
        name: "RetrievedDocument",
        error_group: "[retrieved-document] invalid retrieved document",
        erreur_type: "Invalid document from retriever : #{retriever.name.to_s}",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          retriever: retriever.inspect,
          document: document.inspect,
          modifiable: DocumentTools.modifiable?(@temp_file_path).to_s
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
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
