# -*- encoding : UTF-8 -*-
class Configuration < ApplicationRecord
  validates_presence_of :key, :group

  def self.all_element_group_of(value)
    where(group: "#{value}") || []
  end
end