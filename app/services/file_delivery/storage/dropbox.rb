# Used to send multiple files from a pack to Dropbox, for basic and extended, using Dropbox API v2
class FileDelivery::Storage::Dropbox < FileDelivery::Storage::Main
  def execute
    run do
      if metafile.size < @options[:chunk_size]
        client.upload metafile.path, File.read(metafile.local_path), mode: :overwrite
      else
        while metafile.upload_session[:offset] < metafile.size
          chunk = File.read metafile.local_path, @options[:chunk_size], metafile.upload_session[:offset]
          if metafile.upload_session[:offset] == 0
            metafile.upload_session = client.upload_session_start(chunk).to_hash.with_indifferent_access
          elsif metafile.upload_session[:offset] + @options[:chunk_size] < metafile.size
            client.upload_session_append_v2 metafile.upload_session, chunk
            metafile.upload_session[:offset] += @options[:chunk_size]
          else
            client.upload_session_finish metafile.upload_session, { mode: :overwrite, path: metafile.path }, chunk
            metafile.upload_session[:offset] = metafile.size
          end
        end
      end
    end
  end

  private

  def init_client
    DropboxApi::Client.new(@storage.access_token)
  end

  def max_number_of_threads
    10
  end

  def list_files
    begin
      result = client.list_folder @folder_path
      data = result.entries
      while result.has_more?
        result = client.list_folder_continue result.cursor
        data += result.entries
      end
    rescue DropboxApi::Errors::NotFoundError
      data = []
    end

    data.map { |e| [e.name, e.try(:size)] }
  end

  def retryable_failure?(error)
    (error.is_a?(DropboxApi::Errors::BasicError) || error.is_a?(DropboxApi::Errors::HttpError) || error.is_a?(Faraday::TimeoutError) || error.is_a?(Faraday::ConnectionFailed)) && !manageable_failure?(error)
  end

  def manageable_failure?(error)
    (error.class == DropboxApi::Errors::UploadWriteFailedError && error.message.match(/\Apath\/insufficient_space/)) ||
    (error.class == DropboxApi::Errors::HttpError && error.message.match(/invalid_access_token/))
  end

  def manage_failure(error)
    if (error.class == DropboxApi::Errors::UploadWriteFailedError && error.message.match(/\Apath\/insufficient_space/))
      @storage.try(:disable)
      Notifications::Dropbox.new({ user: @storage.try(:user) }).notify_dropbox_insufficient_space if @storage.try(:user)
    elsif (error.class == DropboxApi::Errors::HttpError && error.message.match(/invalid_access_token/))
      @storage.try(:reset_access_token)
      Notifications::Dropbox.new({ user: @storage.try(:user) }).notify_dropbox_invalid_access_token if @storage.try(:user)
    end
  end
end
