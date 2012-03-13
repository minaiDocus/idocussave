class DocumentContentIndex
  INDEX_PATH = "#{Rails.root}/tmp/document_content.index"
  
  class << self
  
    def init
      File.new(INDEX_PATH,"w")
    end
    
    def indexed_lines
      lines = File.open(INDEX_PATH,"r").readlines rescue []
      lines.map do |line|
        line.chomp
      end
    end
    
    def is_visible line, x_ids, is_document=true
      part = 1 if is_document
      part = 2 if !is_document
      ids = line.split("\t")[part].split(",")
      ok = false
      while(!ids.empty?)
        if x_ids.include? ids[0]
          ok = true
          break
        else
          ids -= [ids[0]]
        end
      end
      ok
    end
    
    def search word, ids, is_document=true, only_word=true, strict=false
      lines = []
      lines = find indexed_lines, word if !strict
      lines = [find_strict(indexed_lines,word)] if strict
      lines = lines.compact
      lines = lines.select do |line|
        is_visible line, ids, is_document
      end      
      if only_word
        lines.map do |line|
          line.split("\t")[0]
        end
      else
        lines
      end
    end
    
    def find_index lines, word
      lines.index{|l| l.match(/^#{word}\t/)}
    end
    
    def find lines, word
      lines.select{|l| l.split("\t")[0].match(/#{word}/)}
    end
    
    def find_strict lines, word
      lines.select{|l| l.match(/^#{word}\t/)}.first
    end
    
    def find_document_ids words, doc_ids
      res_lines = []
      words.each do |word|
        res = search(word,doc_ids,true,false,true).first
        res_lines << res if !res.nil?
      end
      make_dependance res_lines
    end
    
    def find_pack_ids words, pack_ids
      res_lines = []
      words.each do |word|
        res = search(word,pack_ids,false,false,true).first
        res_lines << res if !res.nil?
      end
      make_dependance res_lines, false
    end
    
    def make_dependance lines, document=true
      part = 1 if document
      part = 2 if !document
      valid_ids = []
      lines.each_with_index do |line,index|
        if index == 0
          valid_ids = line.split("\t")[part].split(",")
        else
          ids = line.split("\t")[part].split(",")
          valid_ids = valid_ids.select do |id|
            ids.include? id
          end
        end
      end
      valid_ids
    end
    
    def save_content data
      file = File.open(INDEX_PATH,"w") rescue nil
      if file
        file.write data
        file.rewind
        true
      else
        false
      end
    end
    
    def update lines
      lines = remove_blank lines
      lines = lines.uniq
      lines = remove_duplicate_entries lines
      if save_content lines.join("\n")
        true
      else
        false
      end
    end
    
    def remove_blank lines
      lines - lines.select{|l| l.blank? || l.split("\t")[1].nil? || l == ""}
    end
    
    def remove_duplicate_entries lines
      lines.map do |line|
        s_line = line.split("\t")
        [s_line[0],s_line[1].split(",").uniq.join(","),s_line[2].split(",").uniq.join(",")].join("\t")
      end
    end
    
    def add document, lines=[], do_save=true
      if !document.content_text.nil? || !document.content_text.blank?
        i_lines = lines if !lines.empty?
        i_lines = indexed_lines if lines.empty?
        document.content_text.split.select{|w| w.match(/^\+/)}.each do |word|
          w = word.sub("+","")
          index = find_index i_lines, w
          if index.nil?
            i_lines << "#{w}\t#{document.id},#{document.pack.documents.originals.first.id}\t#{document.pack.id}"
          else
            parts = i_lines[index].split("\t")
            i_lines[index] = "#{parts[0]}\t#{parts[1]},#{document.id}\t#{parts[2]},#{document.pack.id}"
          end
        end
        if do_save
          if update i_lines
            document.update_attributes(:indexed => true)
          end
        else
          i_lines
        end
      end
    end
    
    def remove document, lines=[], do_save=true
      if !document.content_text.nil? || !document.content_text.blank?
        i_lines = lines if !lines.empty?
        i_lines = indexed_lines if lines.empty?
        document.content_text.split.select{|w| w.match(/^\+/)}.each do |word|
          index = find i_lines, word
          if !index.nil?
            i_lines[index] = i_lines[index].sub("#{document.id}","").sub("#{document.pack.originals.first.id}","").sub("#{document.pack.id}")
          end
        end
        if do_save
          if update i_lines
            document.update_attributes(:indexed => false)
          end
        else
          i_lines
        end
      end
    end
    
    def add_pack pack
      lines = indexed_lines
      checkpoint_timer = Time.now
      pack.documents.each do |document|
        if ((Time.now - checkpoint_timer) > 10.seconds)
          sleep(2)
          checkpoint_timer = Time.now
        else
          lines = add document, lines, false
        end
      end
      if update lines
        pack.documents.not_indexed.entries.each do |document|
          document.update_attributes(:indexed => true)
        end
      end
    end
    
    def remove_pack pack
      lines = indexed_lines
      pack.documents.each do |document|
        lines = remove document, lines, false
      end
      if update lines
        pack.documents.each do |document|
          document.update_attributes(:indexed => false)
        end
      end
    end
    
    def process_all
      Pack.all.entries.each do |pack|
        add_pack pack
      end
    end
  
  end
  
end