# -*- encoding : UTF-8 -*-
class Pack::Report < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  has_many   :expenses,     class_name: 'Pack::Report::Expense',    inverse_of: :report, dependent: :destroy
  has_many   :preseizures,  class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :destroy
  has_many   :remote_files, as: :remotable, dependent: :destroy
  has_many   :pre_assignment_deliveries


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
      user.account_book_types.where(name: result).first.try(:get_name) ||
        user.bank_accounts.where(journal: result).first.try(:foreign_journal).presence ||
        result
    else
      result
    end
  end


  def self.failed_delivery(user_ids = [], limit = 50)
    collection = Pack::Report::Preseizure.where.not(delivery_message: '').where.not(delivery_message: nil)
    collection = collection.where(user_id: user_ids) if user_ids.present?

    collection = collection.group(:delivery_message, :report_id)
    collection = collection.order(delivery_tried_at: :desc).limit(limit)

    collection.map do |delivery|
       object = OpenStruct.new
       object.date           = delivery.delivery_tried_at.try(:localtime)
       object.document_count = delivery.report_id ? Pack::Report.find(delivery.report_id).preseizures.where.not(delivery_message: nil).count : 'N/A'

       object.name           = Rails.cache.fetch ['failed_delivery', 'report_name', delivery.report_id.to_s] do
        Pack::Report.find(delivery.report_id).name if delivery.report_id
       end

       object.message = delivery.delivery_message

       object
     end
  end
end
