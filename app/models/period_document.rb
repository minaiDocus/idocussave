# -*- encoding : UTF-8 -*-
class PeriodDocument
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization
  belongs_to :user
  belongs_to :period,                                    inverse_of: :documents
  belongs_to :pack
  has_one    :report,        class_name: 'Pack::Report', inverse_of: :document, dependent: :delete
  has_one    :paper_process, class_name: 'PaperProcess',                        dependent: :delete

  field :name,                    type: String,  default: ''
  field :pieces,                  type: Integer, default: 0
  field :pages,                   type: Integer, default: 0
  field :scanned_pieces,          type: Integer, default: 0
  field :scanned_sheets,          type: Integer, default: 0
  field :scanned_pages,           type: Integer, default: 0
  field :dematbox_scanned_pieces, type: Integer, default: 0
  field :dematbox_scanned_pages,  type: Integer, default: 0
  field :uploaded_pieces,         type: Integer, default: 0
  field :uploaded_pages,          type: Integer, default: 0
  field :fiduceo_pieces,          type: Integer, default: 0
  field :fiduceo_pages,           type: Integer, default: 0
  field :paperclips,              type: Integer, default: 0
  field :oversized,               type: Integer, default: 0
  field :is_shared,               type: Boolean, default: true
  field :scanned_at,              type: Time
  field :scanned_by,              type: String

  validates_presence_of :name
  validates_format_of :name, with: /^#{Pack::CODE_PATTERN} #{Pack::JOURNAL_PATTERN} #{Pack::PERIOD_PATTERN} all$/
  validate :uniqueness_of_name
  validates :paperclips, :numericality => { :greater_than_or_equal_to => 0 }
  validates :oversized,  :numericality => { :greater_than_or_equal_to => 0 }

  scope :for_time, -> start_time, end_time { where(:created_at.gte => start_time.dup, :created_at.lte => end_time.dup) }
  scope :shared, where(is_shared: true)
  scope :scanned, where(:scanned_at.nin => [nil])

  class << self
    def by_created_at
      desc(:created_at).asc(:name)
    end

    def find_by_name(name)
      where(name: name).first
    end

    def find_or_create_by_name(name, period)
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

    def to_csv
      criteria.map do |document|
        [
          I18n.l(document.scanned_at),
          document.name,
          document.paperclips,
          document.oversized,
          document.scanned_by
        ].join(';')
      end.join("\n")
    end
  end

private

  def uniqueness_of_name
    if self.period
      document = self.period.documents.where(name: name).first
      if document and document != self
        errors.add(:name, "Document with name '#{name}' already exist.")
      end
    end
  end
end
