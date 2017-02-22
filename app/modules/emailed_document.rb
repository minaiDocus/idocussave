class EmailedDocument
  attr_reader :temp_documents

  class << self
    attr_accessor :config
  end


  def initialize(mail)
    @mail = mail
    errors # instanciate errors
    save_attachments if valid?
    attachments.each(&:clean_dir)
  end


  def self.configure
    yield config
    update_config
  end


  def self.config
    @config ||= Configuration.new
  end


  def self.config=(new_config)
    config.address    = new_config['address']    if new_config['address']
    config.port       = new_config['port']       if new_config['port']
    config.user_name  = new_config['user_name']  if new_config['user_name']
    config.password   = new_config['password']   if new_config['password']
    config.enable_ssl = new_config['enable_ssl'] if new_config['enable_ssl']
    update_config
  end


  def self.update_config
    Mail.defaults do
      retriever_method :pop3, address: EmailedDocument.config.address,
                              port: EmailedDocument.config.port,
                              user_name: EmailedDocument.config.user_name,
                              password: EmailedDocument.config.password,
                              enable_ssl: EmailedDocument.config.enable_ssl
    end
  end


  def self.fetch_all
    is_ok = true

    Mail.find_and_delete do |mail|
      begin
        EmailedDocument.receive(mail)
      rescue => e
        is_ok = false
        mail.skip_deletion
        Airbrake.notify(e)
      end
    end

    is_ok
  end


  def self.receive(mail, rescue_error = true)
    email = Email.where(message_id: mail.message_id).first

    unless email
      email                       = Email.new
      email.message_id            = mail.message_id
      email.originally_created_at = mail.date
      email.to                    = mail.to.first
      email.from                  = mail.from.first
      email.subject               = mail.subject
      email.from_user             = User.find_by_email(mail.from.first)
      email.to_user               = User.where(email_code: mail.to.first.split('@')[0]).first

      email.save

      Rails.logger.info(email.inspect)

      Dir.mktmpdir do |dir|
        file_path = "#{dir}/#{email.id}.eml"

        File.open file_path, 'w' do |f|
          f.write mail.to_s
        end

        email.update_attribute(:original_content, File.open(file_path))
      end
    end

    if email.processed? || email.unprocessable?
      email
    else
      begin
        if email.to_user.try(:options).try(:is_upload_authorized)
          emailed_document = EmailedDocument.new mail

          email.attachment_names = emailed_document.attachments.map(&:name) unless email.attachment_names.present?
          email.size             = emailed_document.total_size              unless email.size > 0
          email.save

          if emailed_document.valid?
            email.success

            emailed_document.temp_documents.each do |temp_document|
              email.temp_documents << temp_document
            end

            email.save

            if emailed_document.user.is_mail_receipt_activated
              EmailedDocumentMailer.notify_success(email, emailed_document).deliver_now
            end
          else
            email.update_attribute(:errors_list, emailed_document.errors)
            email.failure
            emailed_document.user && EmailedDocumentMailer.notify_failure(email, emailed_document).deliver_now
          end
          [emailed_document, email]
        else
          email.reject
          email
        end
      rescue => e
        email.error unless email.error?
        if email.to_user && !email.is_error_notified
          attachment_names = mail.attachments.map(&:filename).select do |filename|
            File.extname(filename).casecmp('.pdf').zero?
          end
          EmailedDocumentMailer.notify_error(email, attachment_names).deliver_now
          email.update_attribute(:is_error_notified, true)
        end
        if rescue_error
          Airbrake.notify e
          email
        else
          raise e
        end
      end
    end
  end


  def file_name
    "#{user.code}_#{journal}_#{period}.pdf"
  end

  def email_code
    @email_code ||= @mail.to.first.split('@')[0]
  end

  def user
    @user ||= User.where(email_code: email_code).first
  end

  def journal
    @journal ||= get_journal
  end

  def period_service
    @period_service ||= PeriodService.new user: @user
  end

  def period
    @period ||= get_period
  end

  def pack_name
    DocumentTools.pack_name file_name
  end

  def attachments
    @attachments ||= get_attachments
  end

  def total_size
    attachments.sum(&:size)
  end

  def valid_total_size?
    total_size <= 10.megabytes
  end

  def valid_attachments?
    @valid_attachments ||= attachments.any? && valid_individual_attachments? && valid_total_size?
  end

  def valid_individual_attachments?
    @valid_individual_attachments ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid?
    end
  end

  def valid_attachment_sizes?
    @valid_attachment_sizes ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid_size?
    end
  end

  def valid_attachment_contents?
    @valid_attachment_contents ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid_content?
    end
  end

  def valid_attachment_pages_numbers?
    @valid_attachment_pages_numbers ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.valid_pages_number?
    end
  end

  def invalid_attachment_contents?
    !valid_attachment_contents?
  end

  def unique_individual_attachments?
    @unique_individual_attachments ||= attachments.inject(true) do |acc, attachment|
      acc && attachment.unique?
    end
  end

  # syntactic sugar ||= does not store false/nil value
  def valid?
    if @valid.nil?
      @valid = user.present? && journal.present? && period.present? && valid_attachments?
    else
      @valid
    end
  end

  def invalid?
    !valid?
  end

  def errors
    @errors ||= get_errors
  end

  private

  def get_journal
    if user && @mail.subject.present?
      user.account_book_types.where(name: @mail.subject.split(' ')[0]).first.try(:name)
    end
  end

  def get_period
    if @mail.subject.present?
      name = @mail.subject.split(' ')[1]
      if name.present?
        period_service.include?(name) ? name : nil
      else
        Period.period_name(period_service.period_duration)
      end
    end
  end

  def get_attachments
    if user.present? && journal.present? && period.present?
      @mail.attachments.select do |attachment|
        supported_attachment_filename? attachment.filename
      end.map { |a| Attachment.new(a, file_name) }
    else
      []
    end
  end

  def supported_attachment_filename?(filename)
    return true if File.extname(filename).casecmp('.pdf').zero?
    return true if File.extname(filename).downcase.in?(UploadedDocument::VALID_EXTENSION) && File.basename(filename) =~ /^ido+\d{1,3}/i
    false
  end

  def get_errors
    _errors = []
    _errors << :code       unless user.present?
    _errors << :journal    unless journal.present?
    _errors << :period     unless period.present?
    _errors << :total_size unless valid_total_size?
    if attachments.any?
      attachments.each do |attachment|
        next if attachment.valid?
        attachment_errors = []
        attachment_errors << attachment.name
        attachment_errors << :size          unless attachment.valid_size?
        attachment_errors << :content       unless attachment.valid_content?
        attachment_errors << :pages_number  unless attachment.valid_pages_number?
        attachment_errors << :already_exist unless attachment.unique?
        _errors << attachment_errors
      end
    else
      _errors << if @mail.attachments.empty?
                   :no_attachments
                 else
                   :no_acceptable_attachments
                 end
    end
    _errors << :unknown unless _errors.any?
    _errors
  end

  def save_attachments
    pack = TempPack.find_or_create_by_name pack_name
    pack.update_pack_state
    @temp_documents = []
    attachments.each do |attachment|
      options = {
        delivery_type:         'upload',
        delivered_by:          @user.code,
        original_file_name:    attachment.name,
        is_content_file_valid: true
      }
      File.open(attachment.file_path) do |file|
        @temp_documents << AddTempDocumentToTempPack.execute(pack, file, options)
      end
    end
    @temp_documents
  end
end
