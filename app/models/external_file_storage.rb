class ExternalFileStorage
  include Mongoid::Document
  include Mongoid::Timestamps
  
  SERVICES = ["Dropbox","Google Drive"]
  
  F_DROPBOX = 2
  F_GOOGLE_DOCS = 4
  
  referenced_in :user
  references_one :dropbox_basic
  references_one :google_doc
  
  field :path, :type => String, :default => "/"
  field :is_path_used, :type => Boolean, :default => true
  field :used, :type => Integer, :default => 0
  field :authorized, :type => Integer, :defaut => 0
  
  def authorize flags
    update_attributes(:authorized => authorized | flags)
  end
  
  def unauthorize flags
    update_attributes(:authorized => authorized ^ ( authorized & flags))
  end
  
  def is_dropbox_basic_authorized?
    authorized & F_DROPBOX > 0
  end
  
  def is_google_docs_authorized?
    authorized & F_GOOGLE_DOCS > 0
  end
  
  def is_authorized? flag
    authorized & flag > 0
  end
  
  def services_authorized
    services  = []
    services << "Dropbox" if authorized & F_DROPBOX > 0
    services << "Google Drive" if authorized & F_GOOGLE_DOCS > 0
    services.join(", ")
  end
  
  def use flags
    trusted_flags = authorized & flags
    if trusted_flags == flags
      update_attributes(:used => used | trusted_flags)
    else
      false
    end
  end
  
  def unuse flags
    update_attributes(:used => used ^ ( used & flags ))
  end
  
  def is_used? flag
    used & flag > 0
  end
  
  def services_used
    services  = []
    services << "Dropbox" if used & F_DROPBOX > 0
    services << "Google Drive" if used & F_GOOGLE_DOCS > 0
    services.join(", ")
  end
  
  def deliver filespath, folder_path=nil, flags=used
    if is_path_used
      delivery_path = path
    else
      delivery_path = folder_path
    end
    
    trusted_flags =  authorized & used & flags
    
    if trusted_flags & F_DROPBOX > 0
      if dropbox_basic
        filespath.each do |filepath|
          dropbox_basic.deliver filepath, delivery_path
        end
      end
    end
    
    if trusted_flags & F_GOOGLE_DOCS > 0
      if google_doc
        filespath.each do |filepath|
          google_doc.deliver filepath, delivery_path
        end
      end
    end
  end
  
end