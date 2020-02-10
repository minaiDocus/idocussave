# -*- encoding : UTF-8 -*-
class JobProcessing < ApplicationRecord

  validates_presence_of :name

  scope :not_finished,  -> { where(finished_at: [nil,''], state: :started) }
  scope :killed,        -> { where(state: :killed) }
  scope :not_killed,    -> { where.not(state: :killed) }

  state_machine initial: :started do
    state :finished
    state :killed
    state :started


    after_transition on: :start do |process, _transition|
      process.started_at  = Time.now
      process.finished_at = nil
      process.save
    end

    after_transition on: :finish do |process, _transition|
      process.finished_at = Time.now
      process.save
    end

    after_transition on: :kill do |process, _transition|
      process.finished_at = Time.now
      process.save
    end

    event :start do
      transition any => :started
    end

    event :finish do
      transition started: :finished
    end

    event :kill do
      transition started: :killed
    end
  end
end