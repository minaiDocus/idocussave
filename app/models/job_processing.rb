# -*- encoding : UTF-8 -*-
class JobProcessing < ApplicationRecord

  validates_presence_of :name

  scope :not_finished, -> { where(finished_at: [nil,''], state: :started) }

  state_machine initial: :started do
    state :finished
    state :aborted
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

    after_transition on: :abort do |process, _transition|
      process.finished_at = Time.now
      process.save
    end

    event :start do
      transition any => :started
    end

    event :finish do
      transition started: :finished
    end

    event :abort do
      transition started: :aborted
    end
  end
end