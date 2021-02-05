# Template class for sending files to external storage
class FileDelivery::Storage::Main
  attr_reader :errors

  # remote_files should be a group of files to be sent into the same folder
  def initialize(storage, remote_files, options={})
    @storage = storage
    @options = {
      max_number_of_threads: max_number_of_threads,
      max_retries:           (options[:max_retries] || 8),
      chunk_size:            150.megabytes,
      path_pattern:          (@storage.respond_to?(:path) ? @storage.path : nil)
    }.merge(options).with_indifferent_access

    if(@storage.class == ::Ftp || @storage.class == ::Sftp) && @storage.organization
      @storage.try(:clean_error)
      @options[:path_pattern] = File.join @storage.root_path, @options[:path_pattern]
    end

    @folder_path = ExternalFileStorage.delivery_path(remote_files.first, @options[:path_pattern]).freeze
    @errors      = []
    @metafiles   = []

    @semaphore = Mutex.new
    @queue     = Queue.new
    @threads   = []

    remote_files.each_with_index do |remote_file, index|
      metafile = ::Storage::Metafile.new(remote_file, @options[:path_pattern], (index+1), remote_files.size)
      @metafiles << metafile
      @queue << metafile
    end

    @threads_count = [@options[:max_number_of_threads], @queue.size].min
  end

  def execute
    raise 'Define me!'
  end

  private

  # Define those methods on the child class
  def init_client; end
  def max_number_of_threads; end
  def list_files; end
  def retryable_failure?(error); end
  def manageable_failure?(error); end
  def manage_failure(error); end
  def before_run; end
  def after_run; end
  def before_retry; end

  def client
    Thread.current[:client] ||= init_client
  end

  def metafile
    Thread.current[:metafile]
  end

  def up_to_date?
    [metafile.name, metafile.size].in? existing_files
  end

  def existing_files
    @semaphore.synchronize do
      @existing_files ||= list_files
    end
  end

  def run(&sender)
    run_concurrently do
      handle_failure do |start_time|
        metafile.sending! metafile.path

        if up_to_date?
          System::Log.info('processing', "#{metafile.description} is up to date (#{(Time.now - start_time).round(3)}s)")
        else
          System::Log.info('processing', "#{metafile.description} sending")

          sender.call

          System::Log.info('processing', "#{metafile.description} sent (#{(Time.now - start_time).round(3)}s)")
        end

        metafile.synced!
      end
    end

    @errors.empty?
  ensure
    manage_failures
  end

  def run_concurrently
    @threads_count.times do
      @threads << Thread.new do
        before_run

        loop do
          begin
            Thread.current[:metafile] = @queue.pop(true)

            yield
          rescue ThreadError => e
            e.message == 'queue empty' ? break : raise
          end
        end

        after_run
      end
    end

  ensure
    @threads.each(&:join)
  end

  def handle_failure
    retries = 0
    begin
      start_time = Time.now
      before_retry if retries > 0
      yield start_time
    rescue => e
      failure_message = "#{metafile.description} failed : [#{e.class}] #{e.message}"
      execution_time = (Time.now - start_time).round(3)
      if retryable_failure?(e)
        retries += 1
        if retries < @options[:max_retries]
          min_sleep_seconds = Float(2 ** (retries/2.0))
          max_sleep_seconds = Float(2 ** retries)
          sleep_duration = rand(min_sleep_seconds..max_sleep_seconds).round(2)
          System::Log.info('processing', "#{failure_message} - retrying in #{sleep_duration} seconds")
          sleep sleep_duration
          retry
        else
          System::Log.info('processing', "#{failure_message} - retrying later (#{execution_time}s)")
          metafile.not_synced! "[#{e.class}] #{e.message}"
        end
      elsif manageable_failure?(e)
        System::Log.info('processing', "#{failure_message} - aborting (#{execution_time}s)")
        metafile.not_retryable! "[#{e.class}] #{e.message}"
      else
        System::Log.info('processing', "#{failure_message} - retrying later (#{execution_time}s)")
        metafile.not_synced! "[#{e.class}] #{e.message}"
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
end
