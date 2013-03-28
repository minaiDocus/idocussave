# -*- encoding : UTF-8 -*-
class UpdateRequest
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :temp_values

  field :values, type: Hash, default: {}

  embedded_in :update_requestable, polymorphic: true
  
  before_save :filter_attributes
  
  def apply
    update_requestable.assign_attributes self.values
  end
  
  def apply!
    apply
    self.values = {}
    save
  end
  
  def filter_attributes
    clean_values = {}
    @temp_values ||= {}
    update_requestable.update_requestable_attributes.each do |attribute|
      if @temp_values[attribute.to_s].present?
        clean_values[attribute.to_s] = @temp_values[attribute.to_s][1]
      end
    end
    self.values = clean_values
  end

  def sync!
    apply
    self.values.reject do |k,v|
      !k.to_s.in?(update_requestable.changed)
    end
    save
  end
end
