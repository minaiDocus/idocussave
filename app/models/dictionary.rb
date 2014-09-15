# -*- encoding : UTF-8 -*-
class Dictionary
  include Mongoid::Document
  include Mongoid::Timestamps

  field :word, type: String

  validates_presence_of :word
  validates_uniqueness_of :word

  index :word, unique: true

  class << self
    def find_one(word)
      where(word: word).first
    end

    def add(word)
      if word.is_a?(String)
        unless self.find_one(word)
          new_word = Dictionary.new(word: word)
          new_word.save!
          return true
        end
        return false
      else
        return false
      end
    end

    def remove(word)
      old_word = Dictionary.find_one(word)
      if old_word
        if old_word.delete
          return true
        else
          return false
        end
        else
        false
      end
    end
  end
end
