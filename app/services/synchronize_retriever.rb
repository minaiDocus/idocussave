# -*- encoding : UTF-8 -*-
class SynchronizeRetriever
  class << self
    def in_parallel(running_time=10.seconds)
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
    if retriever.creating?
      log "#{retriever.user.code} - #{retriever.service_name} - #{retriever.api_id} - create"
      if CreateBudgeaAccount.execute(retriever.user)
        CreateRetrieverConnection.execute(retriever)
      end
    elsif retriever.updating?
      log "#{retriever.user.code} - #{retriever.service_name} - #{retriever.api_id} - update"
      UpdateRetrieverConnection.execute(retriever)
    elsif retriever.synchronizing?
      log "#{retriever.user.code} - #{retriever.service_name} - #{retriever.api_id} - sync"
      SyncRetrieverConnection.execute(retriever)
    elsif retriever.destroying?
      log "#{retriever.user.code} - #{retriever.service_name} - #{retriever.api_id} - destroy"
      DestroyRetrieverConnection.execute(retriever)
    elsif retriever.waiting_data? && retriever.updated_at <= 2.minutes.ago
      retriever.update(error_message: 'Aucune donnée reçu')
      retriever.error
    end
  end

  def log(message)
    @semaphore.synchronize do
      puts message
      logger.info(message)
    end
  end

  def logger
    @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_retriever_sync.log")
  end
end
