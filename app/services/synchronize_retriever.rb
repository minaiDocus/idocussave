# -*- encoding : UTF-8 -*-
class SynchronizeRetriever
  class << self
    def concurrently(running_time=10.seconds)
      new(running_time).execute
    end
  end

  def initialize(running_time=10.seconds)
    @running_time   = running_time
    @queue          = Queue.new
    @threads        = []
    @threads_count  = 10
    @semaphore      = Mutex.new
    @processing_ids = []
  end

  def execute
    start_time = Time.now

    @threads_count.times do
      @threads << Thread.new do
        loop do
          retriever = @queue.pop
          break if retriever.nil?

          process(retriever)
          @semaphore.synchronize do
            @processing_ids -= [retriever.id]
          end
        end
      end
    end

    loop do
      if Time.now < start_time + @running_time
        workers_count = @threads_count - @queue.size
        retrievers = []
        if workers_count > 0
          retrievers = Retriever.not_processed.where(:_id.nin => @processing_ids).limit(workers_count).to_a
        end
        if retrievers.empty?
          sleep(0.5)
        else
          @semaphore.synchronize do
            @processing_ids += retrievers.map(&:id)
          end
          retrievers.each { |r| @queue << r }
        end
      else
        @threads_count.times { @queue << nil }
        break
      end
    end

    @threads.each(&:join)
    nil
  end

private

  def process(retriever)
    log "#{retriever.user.code} - #{retriever.service_name} - #{retriever.budgea_id}/#{retriever.fiduceo_id} - #{retriever.state}"
    if retriever.connector.is_budgea_active?
      CreateBudgeaAccount.execute(retriever.user) if retriever.user.budgea_account.nil?
      SyncBudgeaConnection.execute(retriever)
    end
    if retriever.connector.is_fiduceo_active?
      CreateFiduceoAccount.execute(retriever.user) if retriever.user.fiduceo_id.nil?
      SyncFiduceoConnection.execute(retriever)
    end
  end

  def log(message)
    @semaphore.synchronize do
      logger.info(message)
      logger2.info(message)
    end
  end

  def logger
    @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_retriever_sync.log")
  end

  def logger2
    @@logger2 ||= Logger.new(STDOUT)
  end
end
