class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  before_save :upcase_name
  
  references_and_referenced_in_many :users
  
  field :name, :type => String
  field :position, :type => Integer, :default => 0
  
  slug :name
  
  validates_presence_of :name
  
public
  
  class << self
    def by_position
      order_by(:position.asc)
    end
  end
  
private

  def upcase_name
    self.name = self.name.upcase
  end
  
end
