class DocumentTag
  include Mongoid::Document
  
  referenced_in :user
  referenced_in :document
  
  field :name, :type => String, :default => ""
  
  def generate
    tags = ""
    self.document.pack.name.downcase.gsub('_',' ').split.each do |tag|
      if tag.match(/^([a-z]|[0-9]|-|_)+$/)
        tags += " "+tag
      end
    end
    self.name += tags
    self.save!
    self.name
  end
  
end