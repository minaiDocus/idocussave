class Pack::Report::Preseizure::Account < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  TTC = 1
  HT  = 2
  TVA = 3

  has_many   :entries   , class_name: 'Pack::Report::Preseizure::Entry', inverse_of: :account, dependent: :destroy
  belongs_to :preseizure, class_name: 'Pack::Report::Preseizure'       , inverse_of: :accounts


  accepts_nested_attributes_for :entries


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
end
