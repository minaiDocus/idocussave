class PackDeliveryList
  include Mongoid::Document
  include Mongoid::Timestamps
  
  ALL = 0
  ORIGINAL_ONLY = 1
  SHEETS_ONLY = 2
  
  referenced_in :user
  
  field :queue, :type => Array, :default => []
  
  def simplify(ids)
    ids.map { |id| "#{id}" }
  end
  
  def add!(ids,type=ALL)
    self.queue = self.queue + format_queue(ids,type)
    self.queue = self.queue.uniq
    save
  end
  
  def format_queue(ids,type)
    simplify(ids).map { |id| [id,type] }
  end
  
  def remove!(entries)
    self.queue = self.queue - entries
    save
  end
  
  def reset!
    self.queue = []
    save
  end
  
  def process!
    self.queue.each do |entry|
      pack = Pack.find(entry[0])
      send_file(pack,entry[1])
      remove!([entry])
    end
  end
  
  def send_file(pack,type)
    folder_name = pack.name.gsub(/\s/,'_')
    path = "#{Rails.root}/tmp/#{folder_name}"
    Dir.mkdir(path) if !File.exist?(path)
    Dir.chdir(path)
    
    filesname = []
    if type == ALL || type == ORIGINAL_ONLY
      document = pack.documents.originals.first
      filepath = document.content.path
      system("cp #{filepath} ./")
      filesname << File.basename(filepath)
    end
    if type == ALL || type == SHEETS_ONLY
      documents = pack.documents.without_original.sort { |a,b| a.position <=> b.position }
      sheets_count = documents.size / 2
      sheets_count.times do |i|
        first_path = documents[ i * 2 ].content.path
        second_path = documents[ i * 2 + 1 ].content.path
        name = sheet_name(pack, i)
        combine(first_path, second_path, name)
        filesname << name
      end
    end
    
    service.deliver filesname, info_path(pack.name,self.user)
    system("rm -r #{Rails.root}/tmp/#{folder_name}")
  end
  
  def sheet_name(pack, i)
    pack.name.split(/\s/)[0..2].join("_") + "_" + ("%0.3d" % i) + ".pdf"
  end
  
  def combine(first_path, second_path, name)
    cmd = "pdftk A=#{first_path} B=#{second_path} cat A1 B1 output #{name}"
    puts cmd
    system(cmd)
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
