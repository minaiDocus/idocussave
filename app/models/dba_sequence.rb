# -*- encoding : UTF-8 -*-
class DbaSequence
  include Mongoid::Document
  include Mongoid::Locker

  field :name
  field :counter, type: Integer, default: 1

  validates_presence_of :name
  validates_uniqueness_of :name

  index({ name: 1 }, { unique: true })

  def self.next(name)
    sequence = self.where(name: name).first
    if sequence
      sequence.with_lock(timeout: 1, retries: 100, retry_sleep: 0.01) do
        sequence.with(safe: true).inc(counter: 1).counter
      end
    else
      self.create(name: name).counter
    end
  end

  def self.current(name)
    self.where(name: name).first.try(:counter)
  end
end
