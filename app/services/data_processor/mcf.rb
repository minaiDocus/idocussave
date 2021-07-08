class DataProcessor::Mcf
  class << self
    def execute
      McfDocument.to_retake.each do |mcf_doc|
        new(mcf_doc).execute_retake
      end

      McfDocument.processed_but_not_moved.each do |mcf_doc|
        new(mcf_doc).execute_remove
      end

      McfDocument.to_process.each do |mcf_doc|
        new(mcf_doc).execute_process
      end

      notify_undelivered_files McfDocument.not_delivered_and_not_notified if (Time.now.hour == 16 && Time.now.min >= 0 && Time.now.min <= 15)
    end


     def notify_undelivered_files(lists)
      content = "Dépot document MCF vers iDocus : fichier(s) non reçu(s) : \n"

      lists.each do |mcf_doc|
        content += "> #{mcf_doc.access_token} - #{mcf_doc.original_file_name}\n"
        mcf_doc.update(is_notified: true)
      end
      
      addresses = Array(Settings.first.notify_mcf_errors_to)

      unless addresses.empty? || lists.empty?
       NotificationMailer.notify(addresses, '[iDocus-MCF] - Document(s) non reçu(s)', content)
      end
    end
  end

  def initialize(mcf_document)
    @mcf_document = mcf_document
    @access_token = @mcf_document.access_token
    @file_path    = @mcf_document.cloud_content_object.path
  end

  def execute_process
    @mcf_document.processing

    if not File.exist?(@file_path.to_s)
      sleep(5)
      @file_path = @mcf_document.cloud_content_object.reload.path
      if not File.exist?(@file_path.to_s)
        @mcf_document.needs_retake
      else
        process_file
      end
    else
      process_file
    end
  end

  def execute_retake
    if @mcf_document.can_retake?
      begin
        McfLib::Api::Mcf::Client.new(@access_token).ask_to_resend_file

        System::Log.info('mcf_processing', "[MCF][RESEND REQUEST SUCCESS] -- #{@mcf_document.id}-#{@mcf_document.file_name} => Success")
      rescue => e
        System::Log.info('mcf_processing', "[MCF][RESEND REQUEST ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{e.message}")
      end

      @mcf_document.has_retaken
    elsif @mcf_document.maximum_retake_reach?
      System::Log.info('mcf_processing', "[MCF][RESEND REQUEST ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => Maximum number of retake reached")
      @mcf_document.delivery_fails
    end
  end

  def execute_remove
    move_file
  end

  private

  def process_file
    if @mcf_document.user.try(:options).try(:is_upload_authorized)
      uploaded_document = UploadedDocument.new(File.open(@file_path, "r"),
                                               @mcf_document.original_file_name,
                                               @mcf_document.user,
                                               @mcf_document.journal,
                                               0, # document is always for current period
                                               nil,
                                               "mcf"
                                              )

      if uploaded_document.valid? || uploaded_document.already_exist?
        @mcf_document.processed
        System::Log.info('mcf_processing', "[MCF][FILE PROCESSED] -- #{@mcf_document.id}-#{@mcf_document.file_name}")

        move_file
      else
        System::Log.info('mcf_processing', "[MCF][FILE PROCESS ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{uploaded_document.full_error_messages}")

        uploaded_document.errors.each do |err|
          if err.include? :file_is_corrupted_or_protected
            @mcf_document.needs_retake
          else
            @mcf_document.got_error uploaded_document.full_error_messages
            move_file
            Notifications::McfDocumentsWorker.perform_in(20.minutes)
            return
          end
        end
      end
    else
      @mcf_document.got_error 'Téléversement de document non authorisé'
      move_file
      Notifications::McfDocumentsWorker.perform_in(20.minutes)
    end
  end

  def move_file
    if @mcf_document.is_not_moved
      begin
        McfLib::Api::Mcf::Client.new(@access_token).move_uploaded_file

        System::Log.info('mcf_processing', "[MCF][MOVE SUCCESS] -- #{@mcf_document.id}-#{@mcf_document.file_name} => Success")
        @mcf_document.update(is_moved: true)
      rescue => e
        System::Log.info('mcf_processing', "[MCF][MOVE ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{e.message}")
        @mcf_document.update(is_moved: true) if e.message.match(/"Status"=>909/)
      end
    end
  end
end