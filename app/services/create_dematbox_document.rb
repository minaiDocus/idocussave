# -*- encoding : UTF-8 -*-
class CreateDematboxDocument
  attr_reader :temp_document


  def initialize(args)
    @params = Hash[args.map { |k, v| [k.to_s.underscore, v] }]

    @doc_id          = @params['doc_id']
    @service_id      = @params['service_id']
    @virtual_box_id  = @params['virtual_box_id']
    @improved_scan64 = @params['improved_scan']
    @temp_document   = TempDocument.where(dematbox_doc_id: @doc_id).first if upload?
  end


  def execute
    if valid?
      if @service_id == DematboxServiceApi.config.service_id.to_s
        @temp_document.content              = file
        @temp_document.raw_content          = File.open(@temp_document.content.path)
        @temp_document.dematbox_text        = @params['text']
        @temp_document.dematbox_box_id      = @params['box_id']
        @temp_document.dematbox_service_id  = @params['service_id']
        @temp_document.is_ocr_layer_applied = true

        @temp_document.save

        # INFO : Blank pages are removed, so we need to reassign pages_number
        @temp_document.pages_number = DocumentTools.pages_number(@temp_document.content.path)

        @temp_document.save

        if @temp_document.pages_number > 2 && @temp_document.temp_pack.is_bundle_needed?
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
          dematbox_doc_id:       @params['doc_id'],
          dematbox_box_id:       @params['box_id'],
          dematbox_service_id:   @params['service_id'],
          dematbox_text:         @params['text'],
          is_content_file_valid: true
        }

        @temp_document = AddTempDocumentToTempPack.execute(pack, file, options)
      end

      CreateDematboxDocument.notify_uploaded(@temp_document.id) if Rails.env != 'test'
    end

    clean_tmp
  end


  def pack_name
    DocumentTools.pack_name file_name
  end


  def file_name
    if upload?
      @temp_document.content_file_name
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


  def self.notify_uploaded(id)
    temp_document = TempDocument.find(id)

    DematboxNotifyUploadedWorker.perform_async(temp_document.id)
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
      @dir = Dir.mktmpdir

      file_path = File.join(@dir, file_name)

      File.open file_path, 'w' do |f|
        f.write decoded_data
      end

      @file = File.open(file_path)
    end
  end


  def clean_tmp
    FileUtils.remove_entry @dir if @dir
  end


  def decoded_data
    Base64.decode64(@improved_scan64.gsub(/\\n/, "\n")).force_encoding('UTF-8')
  end


  def user
    @user ||= User.find_by_code(@virtual_box_id)
  end


  def journal
    @journal ||= service.name
  end


  def period_service
    @period_service ||= PeriodService.new user: @user
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
      @is_content_file_valid = DocumentTools.modifiable?(file.path)
    end
  end


  def upload?
    @virtual_box_id == DematboxServiceApi.config.virtual_box_id.to_s
  end
end