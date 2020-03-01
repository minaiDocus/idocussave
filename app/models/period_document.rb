# -*- encoding : UTF-8 -*-
class PeriodDocument < ApplicationRecord
  has_one :report,        class_name: 'Pack::Report', inverse_of: :document, dependent: :delete, foreign_key: :document_id
  has_one :paper_process, class_name: 'PaperProcess',                        dependent: :delete

  belongs_to :pack, optional: true
  belongs_to :user
  belongs_to :period, optional: true, inverse_of: :documents
  belongs_to :organization, optional: true

  validate  :uniqueness_of_name
  validates :paperclips, numericality: { greater_than_or_equal_to: 0 }
  validates :oversized,  numericality: { greater_than_or_equal_to: 0 }
  validates_format_of   :name, with: /\A#{Pack::CODE_PATTERN} #{Pack::JOURNAL_PATTERN} #{Pack::PERIOD_PATTERN} all\z/
  validates_presence_of :name


  scope :shared,   -> { where(is_shared: true) }
  scope :scanned,  -> { where.not(scanned_at: [nil]) }
  scope :for_time, -> (start_time, end_time) { where("created_at >= ? AND created_at <= ?", start_time, end_time) }


  def self.find_or_create_by_name(name, period)
    document = period.documents.find_by_name name
    if document
      document
    else
      document = PeriodDocument.new

      document.name         = name
      document.period       = period
      document.user         = period.user
      document.organization = period.organization
      document.save

      document
    end
  end


  def self.to_csv(collection)
    collection.map do |document|
      [
        I18n.l(document.scanned_at),
        document.name,
        document.paperclips,
        document.oversized,
        document.scanned_by
      ].join(';')
    end.join("\n")
  end

  private


  def uniqueness_of_name
    if period
      document = period.documents.where(name: name).first
      if document && document != self
        errors.add(:name, "Document with name '#{name}' already exist.")
      end
    end
  end
end
