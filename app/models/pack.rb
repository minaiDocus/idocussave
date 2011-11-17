class Pack
  include Mongoid::Document
  include Mongoid::Timestamps

  references_and_referenced_in_many :users
  
  referenced_in :order
  references_many :documents, :dependent => :delete
  
  field :name, :type => String
  field :division, :type => Array
  
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
  
  def get_division_from_pdf
    url = "#{Rails.root}/public#{self.documents.where(:is_an_original => true).first.content.url.sub(/\.pdf.*/,'.pdf')}"
    metadata = `pdftk #{url} dump_data` # vérifier s'il n'y a pas eu d'erreur

    number_of_page = metadata.scan(/NumberOfPages: \d+/).to_s.scan(/\d+/).to_s.to_i

    bookmarks = metadata.scan(/BookmarkTitle: \w+\nBookmarkLevel: \d+\nBookmarkPageNumber: \d+/)

    level_number = 1
    div = []
    unless bookmarks.empty?
      bookmarks.each_with_index do |b,index|
        inter = []
        b.split(/\n/).each_with_index do |info,ind|
          inter << info.split(/: /)[1]
          if ind == 1 && info.split(/: /)[1].to_i == 2
            level_number = 2
          end
        end
        if index == 0
          div << inter
        else
          div[index - 1] << (inter[2].to_i - 1).to_s
          div << inter
        end
      end
      div[div.length - 1] << number_of_page.to_s
    else
      div << [self.name,1,1,number_of_page]
    end

    div = [level_number,div]
    self.division = div
    self.save
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