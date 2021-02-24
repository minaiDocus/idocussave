# -*- encoding : UTF-8 -*-
class Retriever::RetrievedDocument
  attr_reader :temp_document

  def self.process_file(retriever_id, document, count_day=0)
    document      = document.try(:to_unsafe_h) || document
    retriever     = Retriever.find retriever_id
    already_exist = retriever.temp_documents.where(api_id: document['id']).first

    return { success: true, return_object: nil } if count_day >= 3 || already_exist

    client         = Budgea::Client.new(retriever.user.budgea_account.try(:access_token))
    is_success     = false
    tries          = 1
    temp_file_path = ''
    return_object  = nil

    CustomUtils.mktmpdir('retriever_retrieved_document') do |dir|
      file_path  = File.join(dir, 'retriever_processed_file.pdf')

      while tries <= 3 && !is_success
        sleep(tries)
        temp_file_path = client.get_file document['id']

        begin
          if client.response.status == 200
            processed_file = PdfIntegrator.new(File.open(temp_file_path), file_path, 'retrieved_document').processed_file
            Retriever::RetrievedDocument.new(retriever, document, processed_file.path)

            retriever.update(error_message: "") if retriever.error_message.to_s.match(/Certains documents n'ont pas/)
            is_success    = true
            return_object = client.response
            count_day     = 3
          else
            is_success    = false
            return_object = client.response
          end
        rescue Errno::ENOENT => e
          return_object = e
        end
        tries += 1
      end

      Retriever::RetrievedDocument.delay_for(24.hours).process_file(retriever.id, document, (count_day+1)) if !is_success && count_day <= 2
    end

    log_document = {
      subject: "[Retriever::RetrievedDocument] retry get file from retriever #{retriever.name.to_s}",
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
        error_message: return_object.to_s,
        temp_file_path: temp_file_path.to_s
      }
    }

    ErrorScriptMailer.error_notification(log_document).deliver if !is_success

    { success: is_success, return_object: return_object }
  end

  def initialize(retriever, document, temp_file_path)
    @retriever      = retriever
    @user           = retriever.user
    @journal        = retriever.journal
    @document       = document
    @temp_file_path = temp_file_path

    CustomUtils.mktmpdir('retriever_retrieved_document_2') do |dir|
      @dir = dir

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
          subject: "[Retriever::RetrievedDocument] invalid retrieved document #{retriever.name.to_s}",
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

      @file.close if @file
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
    @valid ||= valid_extension? && DocumentTools.modifiable?(@temp_file_path)
  end

  def valid_extension?
    File.extname(@document['url'].to_s) == '.pdf'
  end

  def invalid?
    !valid?
  end

  def period_service
    @period_service ||= Billing::Period.new user: @user
  end

  def period
    @period ||= Period.period_name period_service.period_duration, 0
  end

  def file
    if @file
      @file
    else
      file_path = File.join(@dir, file_name)
      FileUtils.cp @temp_file_path, file_path
      @file = File.open(file_path, 'r')
    end
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
