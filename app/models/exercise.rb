# -*- encoding : UTF-8 -*-
class Exercise
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :start_date, type: Date
  field :end_date,   type: Date
  field :is_closed,  type: Boolean, default: false

  validates_presence_of :start_date, :end_date
  validate :uniqueness_of_date

  scope :opened, -> { where(is_closed: false) }
  scope :closed, -> { where(is_closed: true) }

private

  def uniqueness_of_date
    if (exercise = user.exercises.where(start_date: start_date, end_date: end_date).first) && exercise != self
      errors.add(:start_date, :taken)
      errors.add(:end_date, :taken)
    end
  end
end
