# -*- encoding : UTF-8 -*-
class GoogleDriveSyncService
  attr_reader :client, :session

  def initialize(google_doc)
    @google_doc = google_doc
    @client = GoogleDrive::Client.new
  end


  def init_session
    begin
      if @google_doc.token.present? && @google_doc.token_expires_at && @google_doc.token_expires_at > 10.minutes.from_now
        @session = @client.load_session(@google_doc.token)
      elsif @google_doc.refresh_token.present?
        @session = @client.new_session(@google_doc.refresh_token)

        @google_doc.update(
          token: @client.access_token.token,
          token_expires_at: Time.at(@client.access_token.expires_at)
        )
      else
        @session = nil
      end

      @session.files if @session
    rescue Google::APIClient::AuthorizationError => e
      @error   = e
      @session = nil

      case e.result.response.status
      when 401
        @google_doc.update(token: '', token_expires_at: nil)
        init_session
      when 403
        @google_doc.reset
      end

    rescue OAuth2::Error => e
      if e.message =~ /Token has been revoked/
        @error   = e
        @session = nil
        @google_doc.reset
      else
        raise
      end
    end

    @session
  end


  def sync(remote_files)
    session = init_session

    if session
      remote_files.each_with_index do |remote_file, index|
        remote_path ||= ExternalFileStorage.delivery_path(remote_files.first, @google_doc.path)

        begin
          collection = session.root_collection.find_or_create_subcollections(remote_path)
        rescue => e
          remote_file.not_synced!("[#{e.class}] #{e.message}")
        end

        send_file(collection, remote_file, remote_path, index) if collection
      end
    else
      remote_files.each do |remote_file|
        if @error
          if @error.class == OAuth2::Error
            remote_file.not_synced!("[#{@error.class}] #{@error.message}")
          elsif @error.result.response.status.in?([401, 403])
            remote_file.not_synced!("#{@error.result.response.status}: Invalid Credentials.")
          else
            remote_file.not_synced!("#{@error.result.response.status}: #{@error.result.body}")
          end
        else
          remote_file.not_synced!('No credentials configured.')
        end
      end
    end
  end


  def send_file(collection, remote_file, remote_path, index)
    tries = 0

    begin
      remote_filepath = File.join(remote_path, remote_file.name)
      remote_file.sending!(remote_filepath)

      print "\t[#{'%0.3d' % (index + 1)}] #{remote_filepath} sending..."

      mimetype = DocumentTools.mimetype(remote_file.name)

      collection.upload_from_file(remote_file.local_path, remote_file.name, content_type: mimetype, convert: false)

      remote_file.synced!
      print "done\n"
    rescue => e
      tries += 1

      print " failed : [#{e.class}] #{e.message}\n"

      if tries < 3
        retry
      else
        puts "\t[#{'%0.3d' % (index + 1)}] Retrying later"

        remote_file.not_synced!("[#{e.class}] #{e.message}")
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
        File.extname(attachment.filename).casecmp('.pdf').zero?
      end.map { |a| Attachment.new(a, file_name) }
    else
      []
    end
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
        attachment_errors << :size         unless attachment.valid_size?
        attachment_errors << :content      unless attachment.valid_content?
        attachment_errors << :pages_number unless attachment.valid_pages_number?

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
