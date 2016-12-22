# -*- encoding : UTF-8 -*-
class DbaSequence < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name


  def self.next(name)
    sequence = where(name: name).first

    if sequence
      sequence.with_lock(timeout: 1, retries: 100, retry_sleep: 0.01) do
        sequence.counter = sequence.counter + 1
        sequence.save
      end

      sequence.counter
    else
      create(name: name).counter
    end
  end


  def self.current(name)
    where(name: name).first.try(:counter)
  end
end
