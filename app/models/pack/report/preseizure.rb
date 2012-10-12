class Pack::Report::Preseizure
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :report, class_name: 'Pack::Report', inverse_of: :preseizures
  referenced_in :piece, class_name: "Pack::Piece", inverse_of: :preseizure
  references_many :accounts, class_name: 'Pack::Report::Preseizure::Account', inverse_of: :preseizure, dependent: :delete

  field :date,          type: Time
  field :deadline_date, type: Time
  field :observation,   type: String
  field :position,      type: Integer

  def self.to_csv
    self.by_position.map { |preseizure| preseizure.accounts.to_csv }.join("\n")
  end

  def self.by_position
    asc(:position)
  end
end
