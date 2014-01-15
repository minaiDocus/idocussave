# -*- encoding : UTF-8 -*-
class DematboxDocument
  attr_reader :temp_document

  def initialize(args)
    params = Hash[args.map {|k, v| [k.to_s.underscore, v] }]

    @current_time    = params['current_time'] || Time.now
    @virtual_box_id  = params['virtual_box_id']
    @service_id      = params['service_id']
    @improved_scan64 = params['improved_scan']
    @doc_id          = params['doc_id']
    if valid?
      pack = TempPack.find_or_create_by_name pack_name
      options = {
        delivered_by:          user.code,
        delivery_type:         'dematbox_scan',
        dematbox_doc_id:       params['doc_id'],
        dematbox_box_id:       params['box_id'],
        dematbox_service_id:   params['service_id'],
        dematbox_text:         params['text'],
        is_content_file_valid: true
      }
      @temp_document = pack.add file, options
      DematboxDocument.notify_uploaded(@temp_document.id) if Rails.env != 'test'
    end
    clean_tmp
  end

  def pack_name
    DocumentTools.pack_name file_name
  end

  def file_name
    "#{user.code}_#{journal}_#{period}.pdf"
  end

  def valid?
    dematbox.present? && service.present? && content_file_valid? && @doc_id.present?
  end

  def invalid?
    !valid?
  end

  class << self
    def notify_uploaded(id)
      temp_document  = TempDocument.find id
      result = DematboxApi.notify_uploaded temp_document.dematbox_doc_id, temp_document.dematbox_box_id, 'OK'
      if result == '200:OK'
        temp_document.dematbox_is_notified = true
        temp_document.dematbox_notified_at = Time.now
        temp_document.save
      else
        result
      end
    end
    handle_asynchronously :notify_uploaded, priority: 0
  end

private

  def dematbox
    @dematbox ||= Dematbox.find_by_number(@virtual_box_id)
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
      @file = File.open(file_path, 'w')
      @file.write decoded_data
      @file.close
      @file
    end
  end

  def clean_tmp
    FileUtils.remove_entry @dir if @dir
  end

  def decoded_data
    Base64::decode64(@improved_scan64.gsub(/\\n/,"\n")).
      force_encoding('UTF-8')
  end

  def user
    @user ||= dematbox.user
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
        prev_period_offset = @current_time < period_service.prev_expires_at ? 1 : 0
      else
        prev_period_offset = 1
      end
    end
    @period ||= Scan::Period.period_name period_service.period_duration, prev_period_offset
  end

  def content_file_valid?
    if @is_content_file_valid != nil
      @is_content_file_valid
    else
      @is_content_file_valid = DocumentTools.modifiable?(file.path)
    end
  end
end
