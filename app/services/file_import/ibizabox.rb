class FileImport::Ibizabox
  class << self
    def update_folders(user)
      return false unless user.organization.ibiza.try(:first_configured?) && user.uses?(:ibiza)
      folder_ids = if user.ibizabox_folders.exists?
        user.account_book_types.map(&:id) - user.ibizabox_folders.map(&:journal_id)
      else
        user.account_book_types.map(&:id)
      end
      folder_ids.map do |folder_id|
        user.ibizabox_folders.create(journal_id: folder_id)
      end
    end

    def execute(folder)
      new(folder).execute
    end

    def get_accessible_journals(user)
      client = user.organization.try(:ibiza).try(:first_client)

      if client
        client.request.clear
        client.company(user.try(:ibiza).try(:ibiza_id)).journal
        client.request.run

        if client.response.success?
          xml_data = Nokogiri::XML(client.response.body.force_encoding('UTF-8'))
        else
          nil
        end
      end
    end
  end

  def initialize(folder)
    @folder  = folder
    @user    = folder.user
    @journal = folder.journal
    @journal_ref = @journal.use_pseudonym_for_import ? (@journal.pseudonym.presence || @journal.name) : @journal.name
    @initial_documents_count = folder.temp_documents.reload.size
  end

  def execute
    return false if @user.subscription.try(:current_period).try(:is_active?, :ido_x) || !valid?

    @folder.process
    @folder.update_attribute(:last_checked_at, Time.now)
    accessible_ibiza_periods.each do |period|
      if get_ibiza_folder_contents(period)
        process(contents, prev_period_offset_of(period))
      else
        @folder.error_message = client.response.message.try("error").try("details") || client.response.message.to_s
        @folder.save
      end
    end
    is_new_document_present =  @folder.temp_documents.reload.size > @initial_documents_count

    if @folder.is_selection_needed && is_new_document_present && @folder.wait_selection
      @folder.update_attribute(:is_selection_needed, false)
    else
      @folder.ready
    end
    is_new_document_present
  end

  def valid?
    @folder.active? && @user.organization.ibiza.first_configured? && @user.uses?(:ibiza) && accessible_ibiza_journal
  end

  def accessible_ibiza_periods
    start_at_date = period_service.period_duration == 3 ? period_service.start_at.beginning_of_quarter.to_date : period_service.start_at.to_date
    date = period_service.period_duration == 12 ? period_service.end_at.beginning_of_year.to_date : start_at_date
    periods = []
    while date < period_service.end_at.to_date
      periods << ibiza_period_name(date)
      date += 1.month
    end
    periods
  end

  def accessible_ibiza_journal
    client.request.clear
    client.company(@user.try(:ibiza).try(:ibiza_id)).journal
    client.request.path += "/#{@journal_ref}"
    client.request.run

    if client.response.success? && @journal_ref.present?
      xml_data = client.response.body.force_encoding('UTF-8')
      valid = xml_data.match /<presentInGed>1<\/presentInGed>/
    else
      valid = false
    end

    valid
  end

  private

  def get_file(document_id, file_path)
    client.request.clear
    client.company(@user.try(:ibiza).try(:ibiza_id)).ged.file?(document_id)

    if client.response.success?
      xml_file  = Nokogiri::XML(client.response.body.force_encoding('UTF-8'))
      file = File.open file_path, 'w'
      file.write decoded_data(xml_file.at_css('encodedData').content)
      file.flush
      file
    end
  end

  def get_ibiza_folder_contents(period)
    client.request.clear
    client.company(@user.try(:ibiza).try(:ibiza_id)).box.accountingdocuments
    client.request.path += "?journal=#{@journal_ref}&period=#{period}"
    client.request.run

    if client.response.success?
      @xml_data = client.response.body.force_encoding('UTF-8')
    else
      false
    end
  end

  def process(datas, prev_period_offset)
    datas.each do |data|
      file_name   = data.at_css('name').content
      document_id = data.at_css('objectID').content
      unless @user.temp_documents.where(api_id: document_id, delivered_by: 'ibiza').first
        if UploadedDocument.valid_extensions.include?(File.extname(file_name).downcase)
          CustomUtils.mktmpdir('ibizabox_import') do |dir|
            begin
              file_path = File.join(dir, file_name)
              file = get_file(document_id, file_path)

              if File.exist?(file_path) && File.size(file_path) > 0
                Ibizabox::Document.new(file, @folder, document_id, prev_period_offset)
              end
            ensure
              file.close if file
            end
          end

          sleep(5)
        end
      end
    end
  end

  def contents
    Nokogiri::XML(@xml_data).xpath("//wsGedFile[docState[text()='0']]")
  end

  def decoded_data(encoded_data)
    Base64.decode64(encoded_data.gsub(/\\n/, "\n")).force_encoding('UTF-8')
  end

  def period_service
    @period_service ||= Billing::Period.new user: @user
  end

  def ibiza_period_name(time)
    time.strftime("%Y%m")
  end

  def prev_period_offset_of(ibiza_period)
    case period_service.period_duration
      when 1
        accessible_ibiza_periods.reverse.index(ibiza_period)
      when 3
        accessible_ibiza_periods.reverse.index(ibiza_period) / 3
      else 0
    end
  end

  def client
    @client ||= @user.organization.ibiza.first_client
  end
end
