class Composition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :document_ids
  
  referenced_in :user

  def self.create_with_documents(options = {})
    name = options.delete(:name) || "Undefined"
    
    if name == ""
      name = "Undefined".pdf
    end
    
    document_ids = options.delete(:document_ids)
    user_id = options.delete(:user_id)

    documents = Document.find(document_ids).sort_by{|x| document_ids.index(x.id.to_s)}
    
    temp_files = []
    temp_paths = []
    documents.each{|document|
      temp_file = document.content.to_file
      temp_files << temp_file
      temp_paths << File.expand_path(temp_file.path)
    }
    
    
    composition = Composition.where(:user_id => user_id).first
    if composition.nil?
      composition = Composition.new
      composition.user_id = user_id
      cmd = "cd #{Rails.root}/public/system/compositions && mkdir #{composition.id}"
      system(cmd)
    else
      cmd = "cd #{Rails.root}/public/system/compositions/#{composition.id} && rm #{composition.name}.pdf"
      system(cmd)
    end
    combined_name  = "#{Rails.root}/public/system/compositions/#{composition.id}/#{name}.pdf" 
    cmd = "pdftk #{ temp_paths.join(" ") } output #{combined_name}"
    Rails.logger.debug("Will compose new document with #{cmd}")
    system(cmd)
    composition.name = name
    composition.document_ids = document_ids
    composition.save
  end

  def reorder doc_ids
    regenerate doc_ids
  end

  def delete_document document_id
    doc_ids = document_ids.delete_if{|x| x.to_s == document_id}.map(&:to_s)
    regenerate doc_ids
  end

  def regenerate doc_ids
    docs = Document.find(doc_ids).sort_by{|x| doc_ids.index(x.id.to_s)}

    temp_files = []
    temp_paths = []
    docs.each{|document|
      temp_file = document.content.to_file
      temp_files << temp_file
      temp_paths << File.expand_path(temp_file.path)
    }
    combined_name  = "#{Rails.root}/tmp/#{self.id.to_s}.pdf"
    begin
      File.delete(combined_name)
    rescue Errno::ENOENT
      # np if document is not here
    end
    cmd = "pdftk #{ temp_paths.join(" ") } output #{combined_name}"
    Rails.logger.debug("Will reorder composition with #{cmd}")
    system(cmd)
    self.document_ids = doc_ids
    self.save
    self.content = File.new combined_name
    self.save
  end
end
