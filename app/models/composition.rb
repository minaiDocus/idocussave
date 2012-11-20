# -*- encoding : UTF-8 -*-
class Composition
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name
  field :path
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
      temp_file = open(document.content.path)
      temp_files << temp_file
      temp_paths << File.expand_path(temp_file.path)
    }

    composition = Composition.where(:user_id => user_id).first
    if composition.nil?
      composition = Composition.new
      composition.user_id = user_id
      cmd = "cd #{Rails.root}/files/compositions && mkdir #{composition.id}"
      system(cmd)
    else
      cmd = "cd #{Rails.root}/files/compositions/#{composition.id} && rm *.pdf"
      system(cmd)
    end
    combined_name  = "#{Rails.root}/files/compositions/#{composition.id}/#{name}.pdf"
    cmd = "pdftk #{ temp_paths.join(" ") } output #{combined_name}"
    Rails.logger.debug("Will compose new document with #{cmd}")
    system(cmd)
    composition.name = name
    composition.path = combined_name
    composition.document_ids = document_ids
    composition.save
  end
end
