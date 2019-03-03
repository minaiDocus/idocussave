# -*- encoding : UTF-8 -*-
class DematboxService < ApplicationRecord
  validates_presence_of :name, :pid, :type, :state

  self.inheritance_column = :_type_disabled

  scope :groups,   -> { where(type: 'group') }
  scope :services, -> { where(type: 'service') }


  state_machine initial: :unknown do
    state :unknown
    state :verified
    state :not_valid

    event :verified do
      transition [:unknown, :not_valid] => :verified
    end

    event :not_valid do
      transition [:unknown, :verified] => :not_valid
    end
  end


  def to_params(name = self.name)
    {
      type:         type,
      service_name: name,
      service_id:   pid
    }
  end
end
