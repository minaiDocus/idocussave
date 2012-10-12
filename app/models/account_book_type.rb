# -*- encoding : UTF-8 -*-
class AccountBookType
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  ENTRY_TYPE = %w(no expense buying selling bank)
  TYPES_NAME = %w(AC VT BC NDF)

  before_save :upcase_name
  
  referenced_in :owner, class_name: 'User', inverse_of: :my_account_book_types
  references_and_referenced_in_many :clients, class_name: 'User', inverse_of: :account_book_types
  
  field :name,           type: String
  field :description,    type: String,  default: ""
  field :position,       type: Integer, default: 0
  field :entry_type,     type: Integer, default: 0
  field :account_number, type: String
  field :charge_account, type: String
  
  slug :name

  validates_presence_of :name
  validates :name,        length: { in: 2..10 }
  validates :description, length: { in: 2..50 }
  
public

  def compta_processable?
    if entry_type > 0
      true
    else
      false
    end
  end

  def compta_type
    return 'NDF' if self.entry_type == 1
    return 'AC'  if self.entry_type == 2
    return 'VT'  if self.entry_type == 3
    return 'CB'  if self.entry_type == 4
    return nil
  end
  
  class << self
    def by_position
      asc([:position, :name])
    end

    def find_by_slug(txt)
      where(slug: txt).first
    end
  end
  
private

  def upcase_name
    self.name = self.name.upcase
  end
end
