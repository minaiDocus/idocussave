class Software::Cegid < ApplicationRecord
  include Interfaces::Software::Configuration

  belongs_to :owner, polymorphic: true

  validates_inclusion_of :auto_deliver, in: [-1, 0, 1]
end
