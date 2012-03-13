class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  before_save :upcase_name
  
  referenced_in :owner, :class_name => "User", :inverse_of => :my_account_book_types
  references_and_referenced_in_many :clients, :class_name => "User", :inverse_of => :account_book_types
  
  field :name, :type => String
  field :description, :type => String, :default => ""
  field :position, :type => Integer, :default => 0
  
  slug :name
  
  validates :name, :length => { :in => 2..4 }
  validates :description, :length => { :in => 2..50 }
  
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
