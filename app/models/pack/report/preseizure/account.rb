class Pack::Report::Preseizure::Account
  include Mongoid::Document
  include Mongoid::Timestamps

  referenced_in :preseizure, class_name: 'Pack::Report::Preseizure', inverse_of: :accounts

  field :title,     type: String
  field :number,    type: String
  field :credit,    type: Float
  field :debit,     type: Float
  field :lettering, type: String
  field :position,  type: Integer

  def self.to_csv
    self.by_position.map(&:to_csv).join("\n")
  end

  def to_csv
    [
      preseizure.date.try(:strftime,'%d/%m/%Y'),
      preseizure.report.type,
      number,
      debit,
      credit,
      title,
      preseizure.piece.try(:name).try(:gsub,' ','_'),
      lettering,
      preseizure.deadline_date.try(:strftime,'%d/%m/%Y')
    ].join(';')
  end

  def self.by_position
    asc(:position)
  end
end
