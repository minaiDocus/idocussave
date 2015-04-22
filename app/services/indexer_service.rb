# -*- encoding : UTF-8 -*-
class IndexerService
  class << self
    def perform_async(klass, id, operation, time=nil)
      delay(queue: 'index', priority: 5, run_at: time || Time.now).perform klass, id, operation
    end

    def perform(klass, id, operation)
      document = klass.constantize.find id
      if document
        case operation.to_s
        when 'index'
          document.__elasticsearch__.index_document
        when 'delete'
          document.__elasticsearch__.delete_document
        end
      end
    end
  end
end
