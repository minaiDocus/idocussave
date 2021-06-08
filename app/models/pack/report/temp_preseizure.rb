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
    state :valid
    state :invalid
    state :cloned
    state :waiting_validation


    event :waiting_validation do
      transition created: :waiting_validation
    end


    event :invalid do
      transition [:created, :waiting_validation] => :invalid
    end


    event :valid do
      transition [:created, :waiting_validation] => :valid
    end


    event :cloned do
      transition [:valid] => :cloned
    end
  end
end
