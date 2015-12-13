# -*- encoding : UTF-8 -*-
class IndexerService
  class << self
    def perform_async(klass, id, operation, time=nil)
      delay(priority: 1, run_at: time || Time.now).perform klass, id, operation
    end

    def perform(klass, id, operation)
      source = klass.constantize
      case operation.to_s
      when 'index'
        source.find(id).__elasticsearch__.index_document
      when 'delete'
        source.__elasticsearch__.client.delete index: source.index_name, type: klass.downcase, id: id
      end
    end
  end
end
