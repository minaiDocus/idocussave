class McfProcessor
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
    @access_token = mcf_document.access_token
    @file64 = @mcf_document.file64_decoded
  end

  def execute_process
    @mcf_document.processing

    unless @file64.present?
      @mcf_document.needs_retake
    else
      generate_file

      process_file if file_generated?

      FileUtils.remove_entry @tmp_dir
    end
  end

  def execute_retake
    if @mcf_document.can_retake?
      begin
        McfApi::Client.new(@access_token).ask_to_resend_file

        logger.info "[MCF][RESEND REQUEST SUCCESS] -- #{@mcf_document.id}-#{@mcf_document.file_name} => Success"
      rescue => e
        logger.info "[MCF][RESEND REQUEST ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{e.message}"
      end

      @mcf_document.has_retaken
    elsif @mcf_document.maximum_retake_reach?
      logger.info "[MCF][RESEND REQUEST ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => Maximum number of retake reached"
      @mcf_document.delivery_fails
    end
  end

  def execute_remove
    move_file
  end

  private

  def process_file
    uploaded_document = UploadedDocument.new(File.new(@file_path),
                                             @mcf_document.original_file_name,
                                             @mcf_document.user,
                                             @mcf_document.journal,
                                             0, # document is always for current period
                                             nil,
                                             "mcf"
                                            )

    if uploaded_document.valid? || uploaded_document.already_exist?
      @mcf_document.processed
      logger.info "[MCF][FILE PROCESSED] -- #{@mcf_document.id}-#{@mcf_document.file_name}"
      
      move_file
    else
      logger.info "[MCF][FILE PROCESS ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{uploaded_document.full_error_messages}"

      uploaded_document.errors.each do |err|
        if err.include? :file_is_corrupted_or_protected
          @mcf_document.needs_retake
        else
          @mcf_document.got_error uploaded_document.full_error_messages
          move_file
          NotifyMcfDocumentErrorWorker.perform_in(20.minutes)
          return
        end
      end
    end
  end

  def generate_file
    begin
        @tmp_dir = Dir.mktmpdir

        @file_path = File.join(@tmp_dir, @mcf_document.original_file_name)
        File.write @file_path, @file64.force_encoding('UTF-8') unless file_generated?
        @mcf_document.update(is_generated: true)
    rescue => e
      notify_ungenerated_file e.message
      @mcf_document.update(is_notified: true)
      @mcf_document.got_error e.message

      logger.info "[MCF][GENERATION ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{e.message}"
      @file_path = nil
    end
  end

  def file_generated?
    @file_path.present? && File.exist?(@file_path)
  end

  def move_file
    if @mcf_document.is_not_moved
      begin
        McfApi::Client.new(@access_token).move_uploaded_file

        logger.info "[MCF][MOVE SUCCESS] -- #{@mcf_document.id}-#{@mcf_document.file_name} => Success"
        @mcf_document.update(is_moved: true)
      rescue => e
        logger.info "[MCF][MOVE ERROR] -- #{@mcf_document.id}-#{@mcf_document.file_name} => #{e.message}"
        @mcf_document.update(is_moved: true) if e.message.match(/"Status"=>909/)
      end
    end
  end

  def notify_ungenerated_file(error)
    content = "MCF : fichier non générer : #{@mcf_document.id} - #{@mcf_document.original_file_name} - #{@access_token}\n"
    content += "==>#{error}"

    addresses = Array(Settings.first.notify_errors_to)

    unless addresses.empty?
     NotificationMailer.notify(addresses, '[iDocus-MCF] - Document non généré', content)
    end
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_mcf_processing.log")
  end
end