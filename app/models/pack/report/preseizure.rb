class Pack::Report::Preseizure
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :report, class_name: 'Pack::Report', inverse_of: :preseizures
  referenced_in :piece, class_name: "Pack::Piece", inverse_of: :preseizure
  references_many :accounts, class_name: 'Pack::Report::Preseizure::Account', inverse_of: :preseizure, dependent: :delete
  references_many :entries, class_name: 'Pack::Report::Preseizure::Entry', inverse_of: :preseizure, dependent: :delete

  field :date,            type: Time
  field :deadline_date,   type: Time
  field :observation,     type: String
  field :position,        type: Integer
  field :piece_number,    type: String
  field :amount,          type: Float
  field :currency,        type: String
  field :conversion_rate, type: Float
  field :third_party,     type: String

  def period_date
    year = piece.name.split(' ')[2][0..3]
    month = piece.name.split(' ')[2][4..5]
    Time.local(year,month,1)
  end

  def self.by_position
    asc(:position)
  end
end
