class Pack
  include Mongoid::Document
  include Mongoid::Timestamps

  references_and_referenced_in_many :users
  
  referenced_in :order
  references_many :documents, :dependent => :delete
  
  field :name, :type => String
  
  def get_document name
    document = Document.new
    document.is_an_original = true
    document.dirty = true
    document.pack = self
    document.content = File.new "#{Rails.root}/tmp/input_pdf_manuel/#{name}.pdf"
    if document.save!
      self.order.scanned! unless self.order.scanned?
      #system("rm #{Rails.root}/tmp/input_pdf_manuel/#{waybill_number}.pdf")
    end
    
  end
  
  class << self
    def own
      where(:user => self.order.user)
    end
    
    def observed
      excludes(:user => self.order.user)
    end
    
    def shared_by
      self.order.user
    end
  end
end