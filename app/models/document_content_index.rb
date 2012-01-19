class DocumentContentIndex
  INDEX_PATH = "#{Rails.root}/tmp/documents_contents_index/"
  
  attr_reader :data, :header, :body, :formatted_header, :formatted_body, :content_text, :indexed_pack_ids, :indexed_document_ids
  
  include Mongoid::Document
  include Mongoid::Timestamps
  
  referenced_in :user
  
public
  def remove pack_ids
    get_all if @formatted_body.nil?
    
    if pack_ids.is_a?(Array)
      packs = Pack.any_in(:_id => pack_ids)
      packs.each do |pack|
        pack.documents.each do |document|
          content_ary = document.content_text.split
          content_ary.each do |c|
            unless @formatted_body[c].nil?
              if @formatted_body[c][0].is_a?(Array)
                @formatted_body[c][0] -= [pack.id]
                if @formatted_body[c][0].empty?
                  @formatted_body.delete(c)
                elsif @formatted_body[c][1].is_a?(Array)
                  @formatted_body[c][1] -= [document.id]
                end
              end
            end
          end
          @indexed_document_ids -= [document.id]
        end
        @indexed_pack_ids -= [pack.id]
      end
    end
    save_data
  end
  
  def update_data!
    get_all
    
    pack_ids = self.user.packs.collect{|p| p.id} - @indexed_pack_ids
    documents = Document.any_in(:pack_id => pack_ids).not_in(:_id => @indexed_document_ids).without_original.entries
    
    print "processing #{documents.count} document(s)..."
    
    start_time = Time.now
    documents.each do |document|
      if Time.now - start_time > 10
        print "!"
        sleep(2)
        start_time = Time.now
      end
      
      content_ary = document.content_text.split
      content_ary.each do |c|
        if @formatted_body[c]
          @formatted_body[c][0] << document.pack.id
          @formatted_body[c][1] << document.id
        else
          @formatted_body = @formatted_body.merge( { c => [[document.pack.id], [document.id]] } )
        end
      end
      @indexed_pack_ids << document.pack.id
      @indexed_document_ids << document.id
      
      print "."
    end
    
    save_data
  end

  def get_all
    get_data
    get_header
    get_body
    get_formatted_header
    get_formatted_body
    get_indexed_pack_ids
    get_indexed_document_ids
    true
  end

  def get_file_name
    INDEX_PATH + self.user.id.to_s+".index"
  end
  
  def save_data
    uniqify!
    make_text!
    file = File.open(get_file_name,"w")
    file ? file.syswrite(@content_text) : false
  end
  
  def create_data
    File.open(get_file_name,"w+")
  end
  
  def get_data
    file = nil
    begin
      file = File.open(get_file_name,"r") 
    rescue
      file = create_data
    end
    @data = file ? file.readlines : []
  end
  
  def get_header
    @header = @data[0..29]
    @header = [] unless @header
    while @header.length < 31
      @header << ""
    end
    @header
  end
  
  def get_body
    @body = @data[31..(32 + @data.length - 1)] || []
  end
  
  def get_formatted_header
    array_data = []
    @header.each do |h|
      if h.is_a?(String)
        tmp_h =  h.chomp.split(":")
        key = tmp_h[0] || ""
        value = tmp_h[1] || ""
        array_data << [ key, value ]
      else
        array_data << [ "", ""]
      end
    end
    @formatted_header = array_data
  end
  
  def get_formatted_body
    hash_data = {}
    @body.each do |d|
      tmp_d =  d.chomp.split("\t")
      word = tmp_d[0]
      pack_ids = tmp_d[1].split(",")
      document_ids = tmp_d[2].split(",")
      hash_data = hash_data.merge( { word => [ pack_ids, document_ids ] } )
    end
    @formatted_body = hash_data
  end
  
  def get_indexed_pack_ids
    @indexed_pack_ids = @formatted_header[0][1].split(",")
  end
  
  def get_indexed_document_ids
    @indexed_document_ids = @formatted_header[1][1].split(",")
  end
  
  def make_text!
    text = ""
    text += "INDEXED_PACK_IDS : " + @indexed_pack_ids.join(",")
    text += "\n"
    text += "INDEXED_DOCUMENT_IDS : " + @indexed_document_ids.join(",")
    text += "\n"
    @formatted_header[2..29].each do |fh|
      text += fh.join(":") + "\n"
    end
    text += "\n"
    @formatted_body.each do |key,value|
      word = [ key ]
      pack_ids = [ value[0].join(",") ]
      document_ids = [ value[1].join(",") ]
      text += ( word + pack_ids + document_ids ).join("\t") + "\n"
    end
    @content_text = text
  end
  
  def uniqify!
    @formatted_body = @formatted_body.each do |key,value|
      value[0] = value[0].uniq
      value[1] = value[1].uniq
    end
    @indexed_document_ids = @indexed_document_ids.uniq
    @indexed_pack_ids = @indexed_pack_ids.uniq
    true
  end
  
  def sort!
    @formatted_body = @formatted_body.sort { |a,b| a.keys.join.sub(/^\+?/,'') <=> b.keys.join.sub(/^\+?/,'') }
  end
  
  def search word, strict=true
    get_data
    results = []
    if word.is_a?(String)
      body = @data.length > 30 ? @data[31..@data.length-1] : []
      res = body.select { |d| d.match(/^\+?#{word}/) } if strict
      res = body.select { |d| d.match(/.*#{word}.*\t/) } if !strict
      res.each do |r|
        rr = r.split("\t")
        results << [rr[0],rr[1].split(","),rr[2].split(",")]
      end
    elsif word.is_a?(Array)
      word.each do |w|
        body = @data.length > 30 ? @data[31..@data.length-1] : []
        res = body.select { |d| d.match(/^\+?#{w}/) } if strict
        res = body.select { |d| d.match(/.*#{w}.*\t/) } if !strict
        res.each do |r|
          rr = r.split("\t")
          results << [rr[0],rr[1].split(","),rr[2].split(",")]
        end
      end
      words = []
      pack_ids = nil
      document_ids = nil
      results.each do |r|
        words << r[0]
        if pack_ids.nil?
          pack_ids = r[1]
        else
          pack_ids = pack_ids - (pack_ids - r[1])
        end
        if document_ids.nil?
          document_ids = r[2]
        else
          document_ids = document_ids - (document_ids - r[2])
        end
      end
      pack_ids = [] if pack_ids.nil?
      document_ids = [] if document_ids.nil?
      results = [words.uniq,pack_ids.uniq,document_ids.uniq]
    end
    results
  end
  
end