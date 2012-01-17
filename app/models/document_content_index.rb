class DocumentContentIndex
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content, :type => Hash, :default => {}
  field :indexed_document_ids, :type => Array, :default => []
  field :indexed_pack_ids, :type => Array, :default => []
  
  referenced_in :user
  
  def update_content!
    index = self.content
    pack_ids = self.user.packs.collect{|p| p.id} - self.indexed_pack_ids
    
    documents = Document.any_in(:pack_id => pack_ids).not_in(:_id => indexed_document_ids).without_original
    
    print "processing #{documents.count} document(s)..."
    
    start_time = Time.now
    i_document_ids = []
    i_pack_ids = []
    documents.each do |document|
      if Time.now - start_time > 10
        self.content = index
        self.indexed_document_ids += i_document_ids
        self.indexed_document_ids = self.indexed_document_ids.uniq
        self.indexed_pack_ids += i_pack_ids
        self.indexed_pack_ids = self.indexed_pack_ids.uniq
        if self.save
          i_document_ids = []
          i_pack_ids = []
          print "!"          
        else
          print "*"
        end
        sleep(2)
        start_time = Time.now
      end
      
      content_ary = document.content_text.split
      content_ary.each do |c|
        if index[c]
          index[c][0] += [document.pack.id]
          index[c][1] += [document.id]
          index[c][0] = index[c][0].uniq
          index[c][1] = index[c][1].uniq
        else
          index = index.merge({c => [[document.pack.id],[document.id]]})
        end
      end
      
      i_document_ids << document.id
      i_pack_ids << document.pack.id
      
      print "."
    end
    self.content = index
    self.save
  end
  
  def update_content_with d_pack_ids
    if d_pack_ids.is_a?(Array)
      pack_ids = d_pack_ids - self.indexed_pack_ids
      unless pack_ids.empty?
        c_pack_ids = self.user.packs.collect{|p| p.id} - self.indexed_pack_ids
        pack_ids = pack_ids.select{|p| c_pack_ids.include? p}
        documents = Document.any_in(:pack_id => pack_ids).not_in(:_id => indexed_document_ids).without_original
        
        print "processing #{documents.count} document(s)..."
        
        index = self.content
        documents.each do |document|
          content_ary = document.content_text.split
          content_ary.each do |c|
            if index[c]
              index[c][0] += [document.pack.id]
              index[c][1] += [document.id]
              index[c][0] = index[c][0].uniq
              index[c][1] = index[c][1].uniq
            else
              index = index.merge({c => [[document.pack.id],[document.id]]})
            end
          end
          self.indexed_document_ids << document.id
          self.indexed_document_ids = self.indexed_document_ids.uniq
          self.indexed_pack_ids << document.pack.id
          self.indexed_pack_ids = self.indexed_pack_ids.uniq
          
          print "."
        end
        self.content = index
        self.save
      end
    end
  end
  
  def search param, type=2, strict=true
    # recherche de mots
    if type == 2
      keys = self.content.keys
      if  param.is_a?(Array)
        result = []
        param.each do |p|
          result += keys.select{|k| k.match(/#{p}/)}
        end
        result
      else
        keys.select{|k| k.match(/#{param}/)}
      end
    # recherche de pack (0) ou de document (1)
    elsif type == 0 || type == 1
      index = self.content
      if index.is_a?(Hash)
        keys = index.keys
        result_ids = []
        if  param.is_a?(Array)
          param.each_with_index do |p,i|
            key = strict ? keys.select{|k| k.match(/^[\+]*#{p}$/)}.first : keys.select{|k| k.match(/#{p}/)}.first
            if key
              temp_ids = index[key][type]
              if i != 0
                result_ids = temp_ids.select{|id| result_ids.include? id }
              else
                result_ids = temp_ids
              end
            else
              result_ids = []
            end
          end
          result_ids
        else
          key = strict ? keys.select{|k| k.match(/^[\+]*#{param}$/)}.first : keys.select{|k| k.match(/#{param}/)}.first
          if key
            result_ids = index[key][type]
          else
            result_ids = []
          end
          result_ids
        end
      else
        false
      end
    else
      false
    end
  end
  
  def remove pack_ids
    index = self.content
    if pack_ids.is_a?(Array)
      packs = Pack.any_in(:_id => pack_ids)
      packs.each do |pack|
        pack.documents.each do |document|
          content_ary = document.content_text.split
          content_ary.each do |c|
            unless index[c].nil?
              if index[c][0].is_a?(Array)
                index[c][0] -= [pack.id]
                if index[c][0].empty?
                  index.delete(c)
                elsif index[c][1].is_a?(Array)
                  index[c][1] -= [document.id]
                end
              end
            end
          end
          self.indexed_document_ids -= [document.id]
        end
        self.indexed_pack_ids -= [pack.id]
      end
    end
    self.content = index
    self.save
  end
  
end
