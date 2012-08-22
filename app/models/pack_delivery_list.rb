# -*- encoding : UTF-8 -*-
class PackDeliveryList
  include Mongoid::Document
  include Mongoid::Timestamps
  
  ALL           = 0
  ORIGINAL_ONLY = 1
  PIECES_ONLY   = 2
  
  referenced_in :user
  
  field :queue, type: Array, default: []
  
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
    document = pack.documents.originals.first
    filepath = document.content.path
    if type == ALL || type == ORIGINAL_ONLY
      system("cp #{filepath} ./")
      filesname << File.basename(filepath)
    end
    if type == ALL || type == PIECES_ONLY
      pieces = pack.divisions.pieces.sort { |a,b| a.position <=> b.position }
      pieces.each_with_index do |piece,index|
        name = pieces_name(pack, index + 1)
        make_piece(filepath, piece.start, piece.end, name)
        filesname << name
      end
    end
    
    service.deliver filesname, info_path(pack.name,self.user)
    system("rm *")
    Dir.chdir("../")
    system("rm -r #{Rails.root}/tmp/#{folder_name}")
  end
  
  def pieces_name(pack, i)
    pack.name.split(/\s/)[0..2].join("_") + "_" + ("%0.3d" % i) + ".pdf"
  end
  
  def make_piece(filepath, pages_start, pages_end, name)
    system("pdftk A=#{filepath} cat A#{pages_start}-#{pages_end} output #{name}")
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
