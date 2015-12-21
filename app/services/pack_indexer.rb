# -*- encoding : UTF-8 -*-
# NOTE : does not work in test mode, because Delayed::Job is not used
class PackIndexer
  class << self
    def init(pack)
      pack.with_lock(timeout: 1, retries: 100, retry_sleep: 0.01) do
        pack.reload
        unless pack.is_indexing
          pack.timeless.update_attribute(:is_indexing, true)
          execute(pack.id.to_s)
        end
      end
    end

    def execute(pack_id)
      pack = Pack.find pack_id
      pack.with_lock(timeout: 1, retries: 100, retry_sleep: 0.01) do
        if pack.pages.not_extracted.count != 0
          PackIndexer.execute(pack.id.to_s)
        else
          pack.timeless.update_attribute(:is_indexing, false)
        end
      end
      IndexerService.perform(Pack.to_s, pack.id.to_s, 'index')
    end
    handle_asynchronously :execute, priority: 1, run_at: Proc.new { 15.seconds.from_now }
  end
end
