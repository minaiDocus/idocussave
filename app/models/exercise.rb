# -*- encoding : UTF-8 -*-
class Exercise < ApplicationRecord
  belongs_to :user

  validate              :uniqueness_of_date
  validates_presence_of :start_date, :end_date


  scope :opened, -> { where(is_closed: false) }
  scope :closed, -> { where(is_closed: true) }


  def prev
    user.exercises.where(end_date: start_date - 1.day).first
  end


  def next
    user.exercises.where(start_date: end_date + 1.day).first
  end

  private


  def uniqueness_of_date
    if (exercise = user.exercises.where(start_date: start_date, end_date: end_date).first) && exercise != self
      errors.add(:start_date, :taken)
      errors.add(:end_date, :taken)
    end
  end
end
