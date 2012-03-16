class Document::Index
  WORDS_INDEX_PATH = "#{Rails.root}/tmp/document_content_index/words/"

  class << self
    def init
      if !File.exists? "#{Rails.root}/tmp/document_content_index"
        Dir.mkdir "#{Rails.root}/tmp/document_content_index"
      end
      if !File.exists? "#{Rails.root}/tmp/document_content_index/words"
        Dir.mkdir "#{Rails.root}/tmp/document_content_index/words"
      end
      Document::Tree.init
    end
    
    def reset
      Document.without_original.extracted.indexed.entries.each { |d| d.update_attributes :indexed => false }
      Document::Tree.reset
      Dir.chdir WORDS_INDEX_PATH
      system "rm *"
    end
    
    def process
      puts "Beginning index process"
      nb = 0
      
      Pack.all.entries.each do |pack|
        aWords = []
        
        nb += 1
        print "#{nb}::#{pack.name}"
        
        pack.documents.without_original.extracted.not_indexed.each do |document|
          aWords << add(document)
          print "."
        end
        
        aWords.uniq!
        
        Dir.chdir WORDS_INDEX_PATH
        pack.users.each do |user|
          File.open("#{user.id}.words","a") do |f|
            f.write " " + aWords.join(" ")
          end
        end
        print "\n"
      end
      
      remove_duplicated_words_for User.all
    end
    
    def add(document)
      aWords = document.verified_content_text.uniq
      
      # print "\n#{aWords.count}"
      
      # longer_word = longer aWords
      # print "\tlonger:#{longer_word.size}(#{longer_word})"
      
      # shorter_word = shorter aWords
      # print "\tshorter:#{shorter_word.size}(#{shorter_word})\n"
      
      start_time = Time.now
      aWords.each do |sWord|
        if Time.now > start_time + 2.seconds
          sleep(0.4)
          start_time = Time.now
        end
        
        path = Document::Tree.add  sWord
        Dir.chdir path
        
        File.open("#{document.pack.id}.ids","a") do |f|
          f.write " #{document.id}"
        end
      end
      document.update_attributes(:indexed => true)
      aWords
    end
    
    def longer(aWord)
      sWords = ""
      aWord.each do |sW|
        sWords = sW if sWords.size < sW.size
      end
      sWords
    end
    
    def shorter(aWord)
      sWords = "0" * 100
      aWord.each do |sW|
        sWords = sW if sWords.size > sW.size
      end
      sWords
    end
    
    def remove_duplicated_words_for(users)
      users.each do |user|
        remove_duplicated_entries WORDS_INDEX_PATH + "#{user.id}.words"
      end
    end
    
    def remove_duplicated_ids word
      path = Document::Tree.path word
      Dir.glob("*.ids").each do |filename|
        remove_duplicated_entries path + "/" + filename
      end
    end
    
    def remove_duplicated_entries(filepath)
      begin
        sUniqEntries = ""
        File.open(filepath, "r") do |f|
          sUniqEntries = f.readlines[0].split(" ").uniq.join(" ")
        end
        File.open(filepath, "w") do |f|
          f.write sUniqEntries
        end
      rescue
        puts "File #{filepath} doesn't exist."
      end
    end
    
    def search(sWord, user)
      Dir.chdir WORDS_INDEX_PATH
      begin
        results = []
        File.open("#{user.id}.words","r") do |f|
          results = f.read.split(" ").find_all { |w| w.match(sWord) }
        end
        results
      rescue
        []
      end
    end
    
    def find_pack(aWords, user)
      Pack.any_in(:_id => find_pack_ids(aWords, user))
    end
    
    def find_document(aWords, user)
      Document.any_in(:_id => find_document_ids(aWords, user))
    end
    
    def find_pack_ids(aWords, user)
      begin
        result_pack_ids = []
        aWords.each_with_index do |sWord,i|
          Dir.chdir Document::Tree.path(sWord)
          all_pack_ids = Dir.glob("*.ids").map { |f| f.sub(".ids","") }
          authorized_pack_ids = user["pack_ids"].map { |id| id.to_s }
          temp_pack_ids = []
          all_pack_ids.each do |pack_id|
            temp_pack_ids << pack_id if authorized_pack_ids.include? pack_id
          end
          if i == 0
            result_pack_ids = temp_pack_ids
          else
            result_pack_ids = temp_pack_ids.find_all { |id| result_pack_ids.include? id }
          end
        end
        result_pack_ids
      rescue
        []
      end
    end
    
    def find_document_ids(aWords, user)
      document_ids = []
      result_pack_ids = find_pack_ids aWords, user
      result_pack_ids.each_with_index do |pack_id,i|
        inter_ids = []
        aWords.each_with_index do |sWord,k|
          Dir.chdir Document::Tree.path(sWord)
          temp_ids = []
          File.open("#{pack_id}.ids","r") do |f|
            temp_ids = f.read.split(" ")
          end
          if k == 0
            inter_ids = temp_ids
          else
            inter_ids = temp_ids.find_all { |id| inter_ids.include? id }
          end
        end
        document_ids += inter_ids
      end
      document_ids
    end
  end
end