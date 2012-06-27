class PackDeliveryList
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user
  
  field :pack_ids, :type => Array, :default => []
  
  def simplify(ids)
    ids.map { |id| "#{id}" }
  end
  
  def add!(ids)
    self.pack_ids = self.pack_ids + simplify(ids)
    self.pack_ids = self.pack_ids.uniq
    save
  end
  
  def remove!(ids)
    self.pack_ids = self.pack_ids - simplify(ids)
    save
  end
  
  def reset!
    self.pack_ids = []
    save
  end
  
  def process!
    packs = Pack.any_in(:_id => pack_ids)
    packs.each do |pack|
      document = pack.documents.originals.first
      send_file(document)
      remove!(["#{pack.id}"])
    end
  end
  
  def send_file(document)
    filepath = document.content.path
    path = File.dirname(filepath)
    Dir.chdir(path)
    service.deliver [filepath], info_path(document.pack.name,self.user)
  end
  
  def service
    @external_file_storage ||= self.user.find_or_create_external_file_storage
  end
  
  def info_path(name, user=nil)
    name_info = name.split(/\s/)
    info = {}
    info[:code] = name_info[0]
    info[:company] = user.try(:company)
    info[:account_book] = name_info[1]
    info[:year] = name_info[2][0..3]
    info[:month] = name_info[2][4..5]
    info[:delivery_date] = Time.now.strftime("%Y%m%d")
    info
  end
  
  def self.process(id)
    find(id).process!
  end
  
end
