class StaffingFlow < ApplicationRecord
  serialize :params, Hash

  validates_presence_of :kind

  scope :ready_preassignment,       -> { where(kind: 'preassignment', state: 'ready') }
  scope :processing_preassignment,  -> { where(kind: 'preassignment', state: 'processing') }

  scope :ready_grouping,            -> { where(kind: 'grouping', state: 'ready') }
  scope :processing_grouping,       -> { where(kind: 'grouping', state: 'processing') }

  scope :ready_jefacture,           -> { where(kind: 'jefacture', state: 'ready') }
  scope :processing_jefacture,      -> { where(kind: 'jefacture', state: 'processing') }

  scope :processed,                 -> { where(state: 'processed') }

  state_machine initial: :ready do
    state :ready
    state :processing
    state :processed

    event :ready do
      transition any => :ready
    end

    event :processing do
      transition :ready => :processing
    end

    event :processed do
      transition :processing => :processed
    end
  end
end
