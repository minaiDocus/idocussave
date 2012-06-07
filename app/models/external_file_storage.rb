class ExternalFileStorage
  include Mongoid::Document
  include Mongoid::Timestamps
  
  SERVICES = ["Dropbox","Google Drive"]
  
  F_DROPBOX = 2
  F_GOOGLE_DOCS = 4
  
  referenced_in :user
  references_one :dropbox_basic
  references_one :google_doc
  
  field :path, :type => String, :default => "iDocus/:code/:year:month/:account_book/"
  field :is_path_used, :type => Boolean, :default => true
  field :used, :type => Integer, :default => 0
  field :authorized, :type => Integer, :default => 0
  
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
  
  def deliver filespath, info_path={}, flags=used
    trusted_flags =  authorized & used & flags
    delivery_path = ""
    
    if trusted_flags & F_DROPBOX > 0
      if dropbox_basic and dropbox_basic.is_configured?
        delivery_path = is_path_used ? path : dropbox_basic.path
        delivery_path = static_path(delivery_path,info_path)
        dropbox_basic.deliver filespath, delivery_path
      end
    end
    
    if trusted_flags & F_GOOGLE_DOCS > 0
      if google_doc and google_doc.is_configured?
        delivery_path = is_path_used ? path : google_doc.path
        delivery_path = static_path(delivery_path,info_path)
        google_doc.deliver(filespath, delivery_path)
      end
    end
  end
  
  def static_path(delivery_path, info_path)
    delivery_path.gsub!(":code",info_path[:code])
    delivery_path.gsub!(":company",info_path[:company])
    delivery_path.gsub!(":account_book",info_path[:account_book])
    delivery_path.gsub!(":year",info_path[:year])
    delivery_path.gsub!(":month",info_path[:month])
    delivery_path.gsub!(":delivery_date",info_path[:delivery_date])
    delivery_path
  end
  
end