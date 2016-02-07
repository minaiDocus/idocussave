# -*- encoding : UTF-8 -*-
class Pack::Report
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization,                                        inverse_of: :report
  belongs_to :user,                                                inverse_of: :pack_reports
  belongs_to :pack,                                                inverse_of: :report
  belongs_to :document,    class_name: 'PeriodDocument',           inverse_of: :report
  has_many   :expenses,    class_name: "Pack::Report::Expense",    inverse_of: :report, dependent: :destroy
  has_many   :preseizures, class_name: 'Pack::Report::Preseizure', inverse_of: :report, dependent: :destroy
  has_many   :remote_files, as: :remotable, dependent: :destroy
  has_many   :pre_assignment_deliveries

  field :name
  field :type # NDF / AC / CB / VT / FLUX
  field :is_delivered,      type: Boolean, default: false
  field :delivery_tried_at, type: Time
  field :delivery_message
  field :is_locked,         type: Boolean, default: false

  scope :preseizures, -> { not_in(type: ['NDF']) }
  scope :expenses,    -> { where(type: 'NDF') }

  scope :locked,     -> { where(is_locked: true) }
  scope :not_locked, -> { where(is_locked: false) }

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

  class << self
    def failed_delivery(user_ids=[], limit=0)
      match = { '$match' => { 'delivery_message' => { '$ne' => '', '$exists' => true } } }
      match['$match']['user_id'] = { '$in' => user_ids } if user_ids.present?
      group = { '$group' => {
          '_id'       => { 'report_id' => '$report_id', 'delivery_message' => '$delivery_message' },
          'count'     => { '$sum' => 1 },
          'failed_at' => { '$max' => '$delivery_tried_at' }
        }
      }
      sort = { '$sort' => { 'failed_at' => -1 } }
      params = [match, group, sort]
      params << { '$limit' => limit } if limit > 0
      Pack::Report::Preseizure.collection.aggregate(*params).map do |delivery|
        object = OpenStruct.new
        object.date           = delivery['failed_at'].try(:localtime)
        object.document_count = delivery['count'].to_i
        object.name           = Rails.cache.fetch ['failed_delivery', 'report_name', delivery['_id']['report_id'].to_s] do
          Pack::Report.find(delivery['_id']['report_id']).name
        end
        object.message        = delivery['_id']['delivery_message']
        object
      end
    end
  end
end
