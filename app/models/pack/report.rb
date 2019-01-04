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

  scope :ibiza_delivered,           -> { where('is_delivered_to LIKE "%ibiza%"') }
  scope :exact_online_delivered,    -> { where('is_delivered_to LIKE "%exact_online%"') }
  scope :locked,                    -> { where(is_locked: true) }
  scope :expenses,                  -> { where(type: 'NDF') }
  scope :not_locked,                -> { where(is_locked: false) }
  scope :preseizures,               -> { where.not(type: ['NDF']) }

  def self.delivered
    self.where(id: self.all.select{ |s| s.is_delivered? }.collect(&:id))
  end

  def self.not_delivered
    self.where(id: self.all.select{ |s| s.is_not_delivered? }.collect(&:id))
  end

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
    ( self.user.uses_ibiza? && self.is_delivered_to.match(/ibiza/) ) ||
    ( self.user.uses_exact_online? && self.is_delivered_to.match(/exact_online/) )
  end

  def is_not_delivered?
    ( self.user.uses_ibiza? && !self.is_delivered_to.match(/ibiza/) ) ||
    ( self.user.uses_exact_online? && !self.is_delivered_to.match(/exact_online/) )
  end

  def self.failed_delivery(user_ids = [], limit = 50)
    return [] unless user_ids.present? || user_ids.nil?

    ids = self.failed_ibiza_delivery(user_ids) + self.failed_exact_online_delivery(user_ids)

    fields = "max(pack_report_preseizures.delivery_tried_at) as date, count(*) as document_count, pack_reports.name as name, pack_report_preseizures.delivery_message as message"
    Pack::Report::Preseizure.where(id: ids).joins(:report).group(:delivery_message, :name).select(fields).order("date desc").limit(limit).to_a
  end

  def self.failed_ibiza_delivery(user_ids=[])
    return [] unless user_ids.present? || user_ids.nil?

    collection_ids = []
    if user_ids.present?
      User.where(id: user_ids).each do |user|
        collection_ids += Pack::Report::Preseizure.not_ibiza_delivered.where(user_id: user.id).where.not(delivery_tried_at: nil).pluck(:id).to_a if user.uses_ibiza?
      end
    else
      User.customers.active.each do |user|
        collection_ids += Pack::Report::Preseizure.not_ibiza_delivered.failed_ibiza_delivery.where(user_id: user.id).pluck(:id).to_a if user.uses_ibiza?
      end
    end

    collection_ids
  end

  def self.failed_exact_online_delivery(user_ids=[])
    return [] unless user_ids.present? || user_ids.nil?

    collection_ids = []
    if user_ids.present?
      User.where(id: user_ids).each do |user|
        collection_ids += Pack::Report::Preseizure.not_exact_online_delivered.where(user_id: user.id).where.not(delivery_tried_at: nil).pluck(:id).to_a if user.uses_exact_online?
      end
    else
      User.customers.active.each do |user|
        collection_ids += Pack::Report::Preseizure.not_exact_online_delivered.failed_exact_online_delivery.where(user_id: user.id).pluck(:id).to_a if user.uses_exact_online?
      end
    end

    collection_ids
  end

  def delivered_to(software)
    softwares = self.is_delivered_to.split(',') || []
    softwares << software unless softwares.include? software
    self.is_delivered_to = softwares.join(',')
    save
  end

  def is_delivered_to?(software='ibiza')
    softwares = self.is_delivered_to.split(',') || []
    softwares.include? software
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
