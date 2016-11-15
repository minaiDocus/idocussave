# -*- encoding : UTF-8 -*-
class RetrievedData
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :content,                  type: Hash
  field :error_message
  field :processed_connection_ids, type: Array, default: []

  scope :processed,     -> { where(state: 'processed') }
  scope :not_processed, -> { where(state: 'not_processed') }
  scope :error,         -> { where(state: 'error') }

  state_machine initial: :not_processed do
    state :not_processed
    state :processed
    state :error

    event :processed do
      transition :not_processed => :processed
    end

    event :error do
      transition :not_processed => :error
    end

    event :continue do
      transition :error => :not_processed
    end
  end

  def self.remove_oldest
    RetrievedData.where(:created_at.lt => 1.month.ago).destroy_all
  end
end
