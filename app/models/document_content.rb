class DocumentContent
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user
  references_many :words
  
end