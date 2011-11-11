class DocumentContent
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user
  embeds_many :words
  
end