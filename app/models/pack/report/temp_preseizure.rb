class Pack::Report::TempPreseizure < ApplicationRecord
  self.inheritance_column = :_type_disabled

  serialize :raw_preseizure, Hash

  belongs_to :user,                                  inverse_of: :temp_preseizures
  belongs_to :piece,     class_name: 'Pack::Piece',  inverse_of: :temp_preseizures, optional: true
  belongs_to :report,    class_name: 'Pack::Report', inverse_of: :temp_preseizures, optional: true
  belongs_to :operation, class_name: 'Operation',    inverse_of: :temp_preseizures, optional: true
  belongs_to :organization,                          inverse_of: :temp_preseizures


  scope :waiting_validation, -> { where(state: 'waiting_validation', is_made_by_abbyy: true) }

  state_machine initial: :created do
    state :created
    state :is_valid
    state :is_invalid
    state :cloned
    state :waiting_validation


    event :waiting_validation do
      transition created: :waiting_validation
    end


    event :is_invalid do
      transition [:created, :waiting_validation] => :is_invalid
    end


    event :is_valid do
      transition [:created, :waiting_validation] => :is_valid
    end


    event :cloned do
      transition [:is_valid] => :cloned
    end
  end
end
