class UserOptions
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :max_number_of_journals,      type: Integer, default: 5 # infinite
  field :is_preassignment_authorized, type: Boolean, default: false
end
