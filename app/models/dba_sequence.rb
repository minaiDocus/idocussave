class DbaSequence
  include Mongoid::Document

  field :name
  field :counter, :type => Integer, :default => 1

  validates_presence_of :name
  validates_uniqueness_of :name

  index :name, :unique => true

  def self.next name
    self.where(:name => name).first.safely.inc(:counter, 1)
  rescue
    sequence = self.create(:name => name)
    sequence.counter
  end

  def self.current name
    self.where(:name => name).first.try(:counter)
  end
  
end
