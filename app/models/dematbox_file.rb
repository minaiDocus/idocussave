# -*- encoding : UTF-8 -*-
class DematboxFile
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip
  
  field :user_code,          type: String
  field :journal_name,       type: String
  field :period,             type: String
  field :box_id,             type: String
  field :service_id,         type: String
  field :doc_id,             type: String
  field :text,               type: String
  field :content_file_name,  type: String
  field :content_file_type,  type: String
  field :content_file_size,  type: Integer
  field :content_updated_at, type: Time

  field :is_processed,       type: Boolean, default: false
  field :processed_at,       type: Time

  field :is_notified,        type: Boolean, default: false
  field :notified_at,        type: Time

  belongs_to :user
  has_mongoid_attached_file :content, path: ":rails_root/files/#{Rails.env.test? ? 'test_' : ''}attachments/dematbox_files/:id/:filename"

  before_post_process :rename_content

  scope :processed,     where: { is_processed: true }
  scope :not_processed, where: { is_processed: false }
  scope :old,           where: { :created_at.lt => 1.month.ago }

  class << self
    def destroy_old
      DematboxFile.old.each do |dematbox_file|
        dematbox_file.destroy
        print '.'
      end.count
    end

    def prepare
      files_groups = DematboxFile.not_processed.asc(:created_at).group_by do |file|
        file.basename
      end
      filenames  = []
      user_codes = []
      if files_groups.any?
        Rails.logger.info "#### [#{Time.now}] DematboxFile beginning preparation ####"
        files_groups.each do |name, files|
          journal = files.first.journal

          path = File.join([RegroupSheet::FILES_PATH,Time.now.strftime('%Y%m%d')])
          cached_path = RegroupSheet::CACHED_FILES_PATH
          FileUtils.mkdir_p(cached_path)
          
          if journal && journal.compta_processable?
            Rails.logger.info "#{name} - #{files.count} - need regroup"
            FileUtils.mkdir_p(path)
            files.each_with_index do |file, index|
              user_codes << file.user.code
              filepath = file.content.path
              filename = file.name(index+1)
              FileUtils.cp(filepath, File.join([path, filename]))
              FileUtils.cp(filepath, File.join([cached_path, filename]))
              file.processed
            end
          else
            Rails.logger.info "#{name} - #{files.count}"
            files.each_with_index do |file, index|
              filename = file.name(index+1)
              FileUtils.cp(file.content.path, File.join([Pack::FETCHING_PATH, filename]))
              filenames << filename
              file.processed
            end
          end
          user_codes.uniq!
          AccountingPlan.update_files_for(user_codes) if user_codes.any?
        end
        Rails.logger.info "#### [#{Time.now}] DematboxFile end of preparation ####"
        filenames
      else
        []
      end
    end

    def from_params(params)
      _params = Hash[params.map {|k, v| [k.to_s.underscore, v] }]
      dematbox_file = DematboxFile.where(doc_id: _params['doc_id']).first
      dematbox_file = DematboxFile.new unless dematbox_file
      dematbox_file.set_params(_params)
      if dematbox_file.user && dematbox_file.save
        dematbox_file.notify_uploaded
      end
      dematbox_file
    end
  end

  def set_params(params)
    dematbox = Dematbox.find_by_number params['virtual_box_id']
    self.user = dematbox.try(:user)
    if self.user
      self.box_id       = params['box_id']
      self.service_id   = params['service_id']
      self.user_code    = self.user.code
      self.journal_name = service.name rescue 'UNKNOWN'
      self.period       = period_name
      self.doc_id       = params['doc_id']
      self.text         = params['text']
      self.content      = f = file(params['improved_scan'])
      f.unlink
    end
  end

  def basename
    "#{user_code}_#{journal_name}_#{period}"
  end

  def name(number=nil)
    if number
      "#{basename}_#{'%03d' % number}.pdf"
    else
      "#{basename}.pdf"
    end
  end

  def journal
    user.account_book_types.where(name: journal_name).first
  end

  def processed
    self.is_processed = true
    self.processed_at = Time.now
    save
  end

  def notify_uploaded
    result = DematboxApi.notify_uploaded self.doc_id, self.box_id, 'OK'
    if result == '200:OK'
      self.is_notified = true
      self.notified_at = Time.now
      save
    else
      result
    end
  end
  handle_asynchronously :notify_uploaded, priority: 3

  def service
    @service ||= user.dematbox.services.where(pid: service_id).first
  end

private

  def period_name
    if period_duration == 1
      (Time.now - period_scale.month).strftime("%Y%m")
    elsif period_duration == 3
      time = (Time.now - period_scale.month).beginning_of_quarter
      case time.month
      when 1
        "#{time.year}T1"
      when 4
        "#{time.year}T2"
      when 7
        "#{time.year}T3"
      when 10
        "#{time.year}T4"
      end
    else
      ''
    end
  end

  def period_duration
    @period_duration ||= user.periods.last.duration rescue 1
  end

  def period_scale
    service.is_for_current_period ? 0 : period_duration
  end

  def file(improved_scan)
    f = Tempfile.new(name)
    f.write decode64(improved_scan)
    f.close
    f
  end

  def decode64(data)
    _data = data.gsub(/\\n/,"\n")
    Base64::decode64(_data).force_encoding('UTF-8')
  end

  def rename_content
    self.content.instance_write :file_name, name
  end
end
