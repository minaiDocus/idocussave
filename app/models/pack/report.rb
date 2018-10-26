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

  scope :locked,      -> { where(is_locked: true) }
  scope :expenses,    -> { where(type: 'NDF') }
  scope :not_locked,  -> { where(is_locked: false) }
  scope :preseizures, -> { where.not(type: ['NDF']) }


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

  def self.failed_delivery(user_ids = [], limit = 50)
    return [] unless user_ids.present? || user_ids.nil?

    if user_ids.nil?
      collection = Pack::Report::Preseizure.not_delivered.where.not(delivery_tried_at: nil)
    else
      collection = Pack::Report::Preseizure.where.not("pack_report_preseizures.delivery_message" => ['',nil])
    end

    collection = collection.where("pack_report_preseizures.user_id" => user_ids) unless user_ids.nil?
    fields     = "max(pack_report_preseizures.delivery_tried_at) as date, count(*) as document_count, pack_reports.name as name, pack_report_preseizures.delivery_message as message"
    collection = collection.joins(:report).group(:delivery_message, :name).select(fields).order("date desc").limit(limit)
    collection.to_a
  end
end
