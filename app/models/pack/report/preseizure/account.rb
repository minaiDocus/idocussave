class Pack::Report::Preseizure::Account
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :preseizure, class_name: 'Pack::Report::Preseizure'       , inverse_of: :accounts
  has_many   :entries   , class_name: 'Pack::Report::Preseizure::Entry', inverse_of: :account, dependent: :delete

  field :type,      type: Integer # TTC / HT / TVA
  field :number,    type: String
  field :lettering, type: String

  def self.get_type(txt)
    if txt == "TTC"
      1
    elsif txt == "HT"
      2
    elsif txt == "TVA"
      3
    else
      nil
    end
  end

  def self.by_position
    asc(:type)
  end
end
