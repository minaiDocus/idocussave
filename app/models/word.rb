class Word
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :content, :type => String
  
  embedded_in :document_content
  has_and_belongs_to_many :documents
  
  validates_presence_of :content
end