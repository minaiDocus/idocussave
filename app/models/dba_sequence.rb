# -*- encoding : UTF-8 -*-
class DbaSequence < ApplicationRecord
  validates_presence_of :name
  validates_uniqueness_of :name

  def self.next(name)
    sequence = where(name: name).first

    if sequence
      sequence.with_lock do
        sequence.reload
        sequence.counter += 1
        sequence.save
        sequence.counter
      end
    else
      create(name: name).counter
    end
  end

  def self.current(name)
    where(name: name).first.try(:counter)
  end
end
