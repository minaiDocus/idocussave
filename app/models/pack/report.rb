# -*- encoding : UTF-8 -*-
class Pack::Report < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  has_many   :expenses,     class_name: 'Pack::Report::Expense',    inverse_of: :report, dependent: :destroy
  has_many   :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :destroy
  has_many   :remote_files, as: :remotable, dependent: :destroy
  has_many   :pre_assignment_deliveries
  has_many   :pre_assignment_exports


  belongs_to :user
  belongs_to :pack
  belongs_to :document, class_name: 'PeriodDocument',           inverse_of: :report, foreign_key: :document_id
  belongs_to :organization

  scope :delivered,                 -> { where.not(is_delivered_to: [nil, '']) }
  scope :not_delivered,             -> { joins('INNER JOIN softwares_settings ON softwares_settings.user_id = pack_reports.user_id').where('is_ibiza_used = 1 OR is_exact_online_used = 1').where(is_delivered_to: [nil, '']) }
  scope :ibiza_delivered,           -> { where('is_delivered_to = "ibiza"') }
  scope :exact_online_delivered,    -> { where('is_delivered_to = "exact_online"') }
  scope :locked,                    -> { where(is_locked: true) }
  scope :expenses,                  -> { where(type: 'NDF') }
  scope :not_locked,                -> { where(is_locked: false) }
  scope :preseizures,               -> { where.not(type: ['NDF']) }

  def journal
    result = name.split[1]
    if user
      user.account_book_types.where(name: result).first.try(:get_name) || result
    else
      result
    end
  end

  def period
    name.split[2] || '0000'
  end

  def is_delivered?
    ( self.user.try(:uses_ibiza?) && is_delivered_to?('ibiza') ) ||
    ( self.user.try(:uses_exact_online?) && is_delivered_to?('exact_online') )
  end

  def is_not_delivered?
    ( self.user.try(:uses_ibiza?) && !is_delivered_to?('ibiza') ) ||
    ( self.user.try(:uses_exact_online?) && !is_delivered_to?('exact_online') )
  end

  def self.failed_delivery(user_ids = [], limit = 50)
    return [] unless user_ids.present? || user_ids.nil?

    _result = Rails.cache.fetch ['report.failed_delivery', user_ids.presence || 'all'], expires_in: 5.minutes do
      collections = []

      if user_ids.present?
        collections = Pack::Report::Preseizure.failed_delivery.where(user_id: user_ids).joins(:report).select(:id, :delivery_tried_at, :delivery_message, :report_id, 'pack_reports.name as name').to_a
      else
        collections = Pack::Report::Preseizure.failed_delivery.joins(:report).select(:id, :delivery_tried_at, :delivery_message, :report_id, 'pack_reports.name as name').to_a
      end

      result = []
      if collections.any?
        collections.sort_by(&:delivery_tried_at).reverse.group_by(&:report_id).each do |report_id, preseizures_by_report|
          preseizures_by_report.group_by(&:delivery_message).each do |message, preseizures|
            preseizures_count     = preseizures.size
            max_date              = preseizures.first.delivery_tried_at
            message_ibiza         = preseizures.first.get_delivery_message_of('ibiza')
            message_exact_online  = preseizures.first.get_delivery_message_of('exact_online')

            if message_ibiza.present? && message_exact_online.present?
              full_message = "-iBiza : #{message_ibiza} <br> -ExactOnline : #{message_exact_online}"
            else
              full_message = message_ibiza.presence || message_exact_online.presence
            end

            result << OpenStruct.new({date: max_date, document_count: preseizures_count, name: preseizures.first.try(:name), message: full_message})
          end
        end
      end

      result
    end

    _result.take(limit)
  end

  def delivered_to(software)
    return true if is_delivered_to?(software)

    # softwares = self.is_delivered_to.split(',') || []
    # softwares << software
    # self.is_delivered_to = softwares.sort.join(',')
    self.is_delivered_to = software
    save
  end

  def remove_delivered_to
    temp_delivered_to = self.is_delivered_to
    temp_delivered_to = temp_delivered_to.gsub('ibiza', '') if self.user.uses_ibiza?
    temp_delivered_to = temp_delivered_to.gsub('exact_online', '') if self.user.uses_exact_online?
    temp_delivered_to = temp_delivered_to.gsub(/^[,]+/, '')
    temp_delivered_to = temp_delivered_to.gsub(/[,]+$/, '')
    temp_delivered_to = temp_delivered_to.gsub(/(,)+/, ',')
    update_attribute(:is_delivered_to, temp_delivered_to)
  end

  def is_delivered_to?(software='ibiza')
    self.is_delivered_to.match(/#{software}/) ? true : false
  end

  def set_delivery_message_for(software='ibiza', message)
    begin
      mess = self.delivery_message.present? ? JSON.parse(self.delivery_message) : {}
    rescue
      mess = {}
    end

    if message.present?
      mess[software.to_s] = message
    else
      mess.except!(software.to_s)
    end
    self.delivery_message = mess.to_json.to_s
    save
  end

  def get_delivery_message_of(software='ibiza')
    mess = ''
    if self.delivery_message.present?
      mess = JSON.parse(self.delivery_message) rescue { "#{software.to_s}" => self.delivery_message }
      mess = mess[software.to_s] || ''
    end
    mess
  end
end
