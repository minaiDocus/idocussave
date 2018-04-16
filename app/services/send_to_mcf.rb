class SendToMcf < SendToStorage
  def execute
    run do
      client.upload metafile.local_path, metafile.path
    end
  end

  private

  def before_run
    renew_access_token
  end

  def before_retry
    renew_access_token
  end

  def renew_access_token
    @semaphore.synchronize do
      if @storage.access_token_expires_at < Time.now
        result = client.renew_access_token @storage.refresh_token
        @storage.update(
          access_token: result[:access_token],
          access_token_expires_at: result[:expires_at]
        )
      end

      client.access_token = @storage.access_token if client.access_token != @storage.access_token
    end
  end

  def init_client
    McfApi::Client.new(@storage.access_token)
  end

  def max_number_of_threads
    1
  end

  def list_files
    client.verify_files(@metafiles.map(&:path)).map do |info|
      @metafiles.find do |m|
        m.path == info[:path] && m.fingerprint == info[:md5].downcase
      end
    end
  end

  def up_to_date?
    metafile.in? existing_files
  end

  def retryable_failure?(error)
    error.is_a?(McfApi::Errors::Unauthorized)
  end

  def manageable_failure?(error)
    insufficient_space?(error) || error.class == McfApi::Errors::Unauthorized
  end

  def manage_failure(error)
    if insufficient_space?(error)
      @storage.update(is_delivery_activated: false)
      NotifyMcfError.new(@storage.organization.admins, 'mcf_insufficient_space').execute
    elsif error.class == McfApi::Errors::Unauthorized
      @storage.reset_tokens
      NotifyMcfError.new(@storage.organization.admins, 'mcf_invalid_access_token').execute
    end
  end

  def insufficient_space?(error)
    error.class == McfApi::Errors::Unknown && error.message.match(/StorageLimitReached\":true/)
  end
end
