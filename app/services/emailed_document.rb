# -*- encoding : UTF-8 -*-
class EmailedDocument
  class Configuration
    attr_accessor :address, :port, :user_name, :password, :enable_ssl

    def initialize
      @enable_ssl = true
    end
  end

  class << self
    attr_accessor :config

    def configure
      yield config
      update_config
    end

    def config
      @config ||= Configuration.new
    end

    def config=(new_config)
      config.address    = new_config['address']    if new_config['address']
      config.port       = new_config['port']       if new_config['port']
      config.user_name  = new_config['user_name']  if new_config['user_name']
      config.password   = new_config['password']   if new_config['password']
      config.enable_ssl = new_config['enable_ssl'] if new_config['enable_ssl']
      update_config
    end

    def update_config
      Mail.defaults do
        retriever_method :pop3, :address    => EmailedDocument.config.address,
                                :port       => EmailedDocument.config.port,
                                :user_name  => EmailedDocument.config.user_name,
                                :password   => EmailedDocument.config.password,
                                :enable_ssl => EmailedDocument.config.enable_ssl
      end
    end

    def fetch_all
      is_ok = true
      Mail.find_and_delete do |mail|
        begin
          receive(mail)
        rescue => e
          is_ok = false
          mail.skip_deletion
          Airbrake.notify(e)
        end
      end
      is_ok
    end

    def receive(mail, rescue_error=true)
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

        Dir.mktmpdir do |dir|
          file = File.new "#{dir}/#{email.id}.eml", 'w'
          file.write mail.to_s
          file.close
          email.original_content = file
          email.save
        end
      end

      if email.processed? || email.unprocessable?
        email
      else
        begin
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
              EmailedDocumentMailer.notify_success(mail.from.first, emailed_document).deliver
            end
          else
            email.update_attribute(:errors_list, emailed_document.errors)
            email.failure
            emailed_document.user && EmailedDocumentMailer.notify_failure(mail.from.first, emailed_document).deliver
          end
          [emailed_document, email]
        rescue => e
          email.error unless email.error?
          if email.to_user && !email.is_error_notified
            attachment_names = mail.attachments.map do |attachment|
              attachment.filename
            end.select do |filename|
              File.extname(filename) == '.pdf'
            end
            EmailedDocumentMailer.notify_error(mail.from.first, email.to_user, attachment_names).deliver
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
  end

  attr_reader :temp_documents

  # accept a Mail::Message instance
  def initialize(mail)
    @mail = mail
    save_attachments if valid?
    errors # instanciate errors
    attachments.each(&:clean_dir)
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
    total_size <= 20.megabytes
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

  def invalid_attachment_contents?
    !valid_attachment_contents?
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
    else
      nil
    end
  end

  def get_period
    if @mail.subject.present?
      name = @mail.subject.split(' ')[1]
      if name.present?
        period_service.include?(name) ? name : nil
      else
        Scan::Period.period_name(period_service.period_duration)
      end
    else
      nil
    end
  end

  def get_attachments
    basename = (user.present? && journal.present? && period.present?) ? file_name : nil
    @mail.attachments.select do |attachment|
      File.extname(attachment.filename) == '.pdf'
    end.map { |a| Attachment.new(a, basename) }
  end

  def get_errors
    _errors = []
    _errors << :code       unless user.present?
    _errors << :journal    unless journal.present?
    _errors << :period     unless period.present?
    _errors << :total_size unless valid_total_size?
    if attachments.any?
      attachments.each do |attachment|
        unless attachment.valid?
          attachment_errors = []
          attachment_errors << attachment.name
          attachment_errors << :size    unless attachment.valid_size?
          attachment_errors << :content unless attachment.valid_content?
          _errors << attachment_errors
        end
      end
    else
      if @mail.attachments.empty?
        _errors << :no_attachments
      else
        _errors << :no_acceptable_attachments
      end
    end
    _errors << :unknown    unless _errors.any?
    _errors
  end

  def save_attachments
    pack = TempPack.find_or_create_by_name pack_name
    @temp_documents = []
    attachments.each do |attachment|
      options = {
        delivery_type:         'upload',
        delivered_by:          @user.code,
        original_file_name:    attachment.name,
        is_content_file_valid: true
      }
      File.open(attachment.file_path) do |file|
        @temp_documents << pack.add(file, options)
      end
    end
    @temp_documents
  end

  class Attachment
    attr_accessor :file_path, :file_name

    def initialize(original, file_name)
      @original  = original
      @file_name = file_name
      @file_path = get_file_path
      DocumentTools.remove_pdf_security(@file_path, @file_path) if is_printable_only?
    end

    def name
      @name ||= @original.filename
    end

    def size
      @size ||= @original.body.decoded.length
    end

    def valid_size?
      size <= 5.megabytes
    end

    def valid_content?
      printable?
    end

    # syntactic sugar ||= does not store false/nil value
    def printable?
      if @printable.nil?
        @printable = DocumentTools.printable? @file_path
      else
        @printable
      end
    end

    # syntactic sugar ||= does not store false/nil value
    def is_printable_only?
      if @is_printable_only_set
        @is_printable_only
      else
        @is_printable_only_set = true
        @is_printable_only = DocumentTools.is_printable_only? @file_path
      end
    end

    def valid?
      valid_size? && valid_content?
    end

    def dir
      @dir ||= Dir.mktmpdir
    end

    def clean_dir
      FileUtils.remove_entry @dir if @dir
    end

  private

    def get_file_path
      f = File.new(File.join(dir, @file_name), 'w')
      f.write @original.body.decoded.force_encoding('UTF-8')
      f.close
      f.path
    end
  end
end
