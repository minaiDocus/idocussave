# -*- encoding : UTF-8 -*-
class Dematbox::CreateDocument
  attr_reader :temp_document


  def initialize(args)
    @params = args.permit!.to_h

    @doc_id          = @params['docId']
    @service_id      = @params['serviceId']
    @virtual_box_id  = @params['virtualBoxId']
    @improved_scan64 = @params['improvedScan']
    @temp_document   = TempDocument.where(dematbox_doc_id: @doc_id).first if upload?
  end


  def execute
    CustomUtils.mktmpdir('dematbox_create_document') do |dir|
      @dir = dir

      if valid?
        if @service_id == DematboxServiceApi.config.service_id.to_s
          # @temp_document.raw_content          = File.open(@temp_document.content.path)
          # @temp_document.content              = file
          @temp_document.dematbox_text        = @params['text']
          @temp_document.dematbox_box_id      = @params['boxId']
          @temp_document.dematbox_service_id  = @params['serviceId']
          @temp_document.is_ocr_layer_applied = true

          content_file = @temp_document.cloud_content_object
          @temp_document.cloud_raw_content_object.attach(File.open(content_file.path), File.basename(content_file.path)) if @temp_document.save
          @temp_document.cloud_content_object.attach(File.open(file.path), File.basename(file.path))

          # INFO : Blank pages are removed, so we need to reassign pages_number
          @temp_document.pages_number = DocumentTools.pages_number(@temp_document.cloud_content_object.path)

          @temp_document.save

          if @temp_document.pages_number > 2 && @temp_document.temp_pack.is_compta_processable?
            @temp_document.bundle_needed
          else
            @temp_document.ready
          end
        else
          pack = TempPack.find_or_create_by_name(pack_name)

          pack.update_pack_state

          options = {
            delivered_by:          user.code,
            delivery_type:         'dematbox_scan',
            dematbox_doc_id:       @params['docId'],
            dematbox_box_id:       @params['boxId'],
            dematbox_service_id:   @params['serviceId'],
            dematbox_text:         @params['text'],
            is_content_file_valid: true
          }

          @temp_document = AddTempDocumentToTempPack.execute(pack, file, options)
        end

        Notifications::DematboxUploaded.new({ temp_document_id: @temp_document.id, remaining_tries: 3 }).async.notify_dematbox_document_uploaded if Rails.env != 'test'
      end
    end
  end


  def pack_name
    DocumentTools.pack_name file_name
  end


  def file_name
    if upload?
      @temp_document.cloud_content_object.filename
    else
      "#{user.code}_#{journal}_#{period}.pdf"
    end
  end


  def valid?

    if upload?
      @temp_document.present? && content_file_valid?
    else
      dematbox.present? && service.present? && @doc_id.present? && content_file_valid?
    end
  end


  def invalid?
    !valid?
  end

  private

  def dematbox
    @dematbox ||= user.try(:dematbox)
  end


  def service
    @service ||= dematbox.services.where(pid: @service_id).first
  end


  def file
    if @file
      @file
    else
      file_path = File.join(@dir, file_name)

      File.open file_path, 'w' do |f|
        f.write decoded_data
      end

      @file = File.open(file_path)
    end
  end


  def decoded_data
    Base64.decode64(@improved_scan64.to_s.gsub(/\\n/, "\n")).force_encoding('UTF-8')
  end


  def user
    @user ||= User.find_by_code(@virtual_box_id)
  end


  def journal
    @journal ||= service.name
  end


  def period_service
    @period_service ||= Billing::Period.new user: @user
  end


  def period
    if service.is_for_current_period
      prev_period_offset = 0
    else
      if period_service.prev_expires_at
        prev_period_offset = Time.now < period_service.prev_expires_at ? 1 : 0
      else
        prev_period_offset = 1
      end
    end

    @period ||= Period.period_name period_service.period_duration, prev_period_offset
  end


  def content_file_valid?
    if !@is_content_file_valid.nil?
      @is_content_file_valid
    else
      @is_content_file_valid = @improved_scan64.present? && DocumentTools.modifiable?(file.path)
    end
  end


  def upload?
    @virtual_box_id == DematboxServiceApi.config.virtual_box_id.to_s
  end
end
