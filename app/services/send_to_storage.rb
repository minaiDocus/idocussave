# Template class for sending files to external storage
class SendToStorage
  attr_reader :errors

  def initialize(storage, remote_files, options={})
    @storage = storage
    @options = {
      max_number_of_threads: max_number_of_threads,
      chunk_size:            150.megabytes,
      path_pattern:          (@storage.respond_to?(:path) ? @storage.path : nil)
    }.merge(options).with_indifferent_access
    @errors    = []

    @semaphore = Mutex.new
    @queue     = Queue.new
    @threads   = []

    remote_files.each_with_index do |remote_file, index|
      @queue << Storage::Metafile.new(remote_file, @options[:path_pattern], (index+1), remote_files.size)
    end

    @threads_count = [@options[:max_number_of_threads], @queue.size].min
  end

  def run(&sender)
    run_concurrently do |client, metafile|
      handle_failure metafile do |start_time|
        metafile.sending! metafile.path

        if up_to_date? client, metafile
          logger.info "#{metafile.description} is up to date (#{(Time.now - start_time).round(3)}s)"
        else
          logger.info "#{metafile.description} sending"

          sender.call client, metafile

          logger.info "#{metafile.description} sent (#{(Time.now - start_time).round(3)}s)"
        end

        metafile.synced!
      end
    end

    @errors.empty?
  ensure
    manage_failures
  end

private

  # Define those methods on the child class
  def _client; end # it should create a new instance each call
  def max_number_of_threads; end
  def up_to_date?(client, metafile); end
  def retryable_failure?(error); end
  def manageable_failure?(error); end
  def manage_failure(error); end

  def run_concurrently
    @threads_count.times do
      @threads << Thread.new do
        client = _client

        loop do
          begin
            metafile = @queue.pop(true)
            yield client, metafile
          rescue ThreadError => e
            e.message == 'queue empty' ? break : raise
          end
        end
      end
    end

  ensure
    @threads.each(&:join)
  end

  def handle_failure(metafile)
    retries = 0
    begin
      start_time = Time.now
      yield start_time
    rescue => e
      failure_message = "#{metafile.description} failed : [#{e.class}] #{e.message}"
      execution_time = (Time.now - start_time).round(3)
      if retryable_failure?(e)
        retries += 1
        if retries < 8
          min_sleep_seconds = Float(2 ** (retries/2.0))
          max_sleep_seconds = Float(2 ** retries)
          sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
          logger.info "#{failure_message} - retrying in #{sleep_duration} seconds"
          sleep sleep_duration
          retry
        else
          logger.info "#{failure_message} - retrying later (#{execution_time}s)"
          metafile.not_synced! "[#{e.class}] #{e.message}"
          Airbrake.notify(e)
        end
      elsif manageable_failure?(e)
        logger.info "#{failure_message} - aborting (#{execution_time}s)"
        metafile.not_retryable! "[#{e.class}] #{e.message}"
      else
        logger.info "#{failure_message} - retrying later (#{execution_time}s)"
        metafile.not_synced! "[#{e.class}] #{e.message}"
        Airbrake.notify(e)
        raise if Rails.env.test?
      end
      @semaphore.synchronize do
        @errors << e
      end
    end
  end

  def manage_failures
    if @storage.class != DropboxExtended
      @errors.uniq { |e| "#{e.class.to_s} #{e.message}" }.each { |e| manage_failure e }
    end
  end

  def logger
    @logger ||= @options[:logger] || Logger.new("#{Rails.root}/log/#{Rails.env}_file_delivery.log")
  end
end
