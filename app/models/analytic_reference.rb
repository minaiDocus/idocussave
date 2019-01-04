class AnalyticReference < ActiveRecord::Base
  has_many :temp_documents
  has_many :pieces, class_name: 'Pack::Piece'

  validate :presence_of_one_analysis
  # validate :total_ventilation_rate

  private

  def presence_of_one_analysis
    if a1_name.blank? && a1_axis1.blank? && a1_axis2.blank? && a1_axis3.blank? && a2_name.blank? && a2_axis1.blank? && a2_axis2.blank? && a2_axis3.blank? && a3_name.blank? && a3_axis1.blank? && a3_axis2.blank? && a3_axis3.blank?
      errors.add(:a1_name, :blank)
      errors.add(:a1_axis1, :blank)
    end
  end

  def total_ventilation_rate
    total_ventilation = a1_ventilation + a2_ventilation + a3_ventilation

    invalid = (a1_name.present? && a1_ventilation == 0 && (a1_axis1.present? || a1_axis2.present? || a1_axis3.present?))
    invalid ||= (a2_name.present? && a2_ventilation == 0 && (a2_axis1.present? || a2_axis2.present? || a2_axis3.present?))
    invalid ||= (a3_name.present? && a3_ventilation == 0 && (a3_axis1.present? || a3_axis2.present? || a3_axis3.present?))

    errors.add(:a1_ventilation, 'invalid ventilation') if total_ventilation != 100 || invalid
  end
end
