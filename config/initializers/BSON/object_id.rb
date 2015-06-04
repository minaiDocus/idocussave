module BSON
  class ObjectId
    def as_json(options = {})
      to_s
    end

    # fix vulnerability, DoS and Injection !, see http://sakurity.com/blog/2015/06/04/mongo_ruby_regexp.html
    def self.legal?(s)
      /\A\h{24}\z/ === s.to_s
    end
  end
end
