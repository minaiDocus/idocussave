# -*- encoding : UTF-8 -*-
class Document::Tree
  TREE_PATH = "#{Rails.root}/tmp/document_content_index/tree"
  
  class << self
    def init
      unless File.exists? TREE_PATH
        Dir.mkdir TREE_PATH
      end
    end
    
    def reset
      Dir.chdir TREE_PATH
      system("rm -r *") 
    end
    
    def add(sWord)
      aLetters = sWord.split("")
      for i in 0..aLetters.count
        path = TREE_PATH + "/" + aLetters[0..i].join("/")
        Dir.mkdir path if !File.exists? path
      end
      TREE_PATH + "/" +aLetters.join("/")
    end
    
    def remove(sWord)
      aLetters = sWord.split("")
      for i in 0..aLetters.count
        length = aLetters.count
        path = TREE_PATH + "/" + aLetters[0..(length - i - 1)].join("/")
        if File.exists? path
          aFiles = Dir.entries(path)
          if ((aFiles - ['.','..']).empty?)
            Dir.rmdir path
          end
        end
      end
      TREE_PATH + "/" +aLetters.join("/")
    end
    
    def search(sWord)
      path = TREE_PATH + "/" + sWord.split("").join("/")
      if File.exists? path
        path
      else
        false
      end
    end
    
    def path(sWord)
      TREE_PATH + "/" + sWord.split("").join("/")
    end
  end
end
