class UploadedFile
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user

  field :file_name, :type => String
  
  validates_presence_of :file_name
  
end
