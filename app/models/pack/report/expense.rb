# -*- encoding : UTF-8 -*-
class Pack::Report::Expense
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :report, class_name: "Pack::Report", inverse_of: :expenses
  referenced_in :piece, class_name: "Pack::Piece", inverse_of: :expense
  references_one :observation, class_name: "Pack::Report::Observation", inverse_of: :expense, dependent: :destroy

  field :amount_in_cents_wo_vat, type: Float
  field :amount_in_cents_w_vat,  type: Float
  field :vat,                    type: Float
  field :vat_recoverable,        type: Float
  field :date,                   type: Date
  field :type,                   type: String
  field :origin,                 type: String
  field :obs_type,               type: Integer

  scope :perso, where: { origin: /^perso$/i }
  scope :pro,   where: { origin: /^pro$/i }

  scope :abnormal, where:  { obs_type: 0 }
  scope :normal,   not_in: { obs_type: [0] }

  def to_row
    [
      (Spreadsheet::Link.new(File.join(["http://www.idocus.com",piece.content.url]), piece.content_file_name) rescue nil),
      (self.date.strftime('%d/%m/%Y') rescue nil),
      observation.to_s,
      self.type,
      self.amount_in_cents_wo_vat,
      self.vat,
      self.vat_recoverable,
      self.amount_in_cents_w_vat
    ]
  end

  def self.total_amount_in_cents_wo_vat
    sum(:amount_in_cents_wo_vat)
  end

  def self.total_amount_in_cents_w_vat
    sum(:amount_in_cents_w_vat)
  end

  def self.total_vat
    sum(:vat)
  end

  def self.total_vat_recoverable
    sum(:vat_recoverable)
  end

  def self.distinct_type
    all.distinct(:type)
  end

  def self.of_type(type)
    where(type: type)
  end
end
