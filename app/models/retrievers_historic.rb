# -*- encoding : UTF-8 -*-
class RetrieversHistoric < ApplicationRecord
  belongs_to :user

  scope :banks,          -> { where("capabilities LIKE '%bank%'") }
  scope :has_operations, -> { where("operations_count > 0") }

  def self.find_or_initialize(attrs)
    historic = RetrieversHistoric.find_by_service_name(attrs[:service_name]) || RetrieversHistoric.new
    historic.assign_attributes(attrs)
    historic.save
  end
end