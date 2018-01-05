class AnalyticReference < ActiveRecord::Base
  has_many :temp_documents
  has_many :pieces, class_name: 'Pack::Piece'

  validates_presence_of :name
  validate :presence_of_one_axis

  private

  def presence_of_one_axis
    if axis1.blank? && axis2.blank? && axis3.blank?
      errors.add(:axis1, :blank)
      errors.add(:axis2, :blank)
      errors.add(:axis3, :blank)
    end
  end
end
