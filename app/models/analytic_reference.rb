class AnalyticReference < ActiveRecord::Base
  has_many :temp_documents
  has_many :pieces, class_name: 'Pack::Piece'

  validate :presence_of_one_analysis

  private

  def presence_of_one_analysis
    if a1_name.blank? && a1_axis1.blank? && a1_axis2.blank? && a1_axis3.blank? && a2_name.blank? && a2_axis1.blank? && a2_axis2.blank? && a2_axis3.blank? && a3_name.blank? && a3_axis1.blank? && a3_axis2.blank? && a3_axis3.blank?
      errors.add(:a1_name, :blank)
      errors.add(:a1_axis1, :blank)
    end
  end
end
