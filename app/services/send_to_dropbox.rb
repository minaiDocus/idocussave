# Used to send multiple files from a pack to Dropbox, for basic and extended, using Dropbox API v2
class SendToDropbox < SendToStorage
  def execute
    run do |client, metafile|
      if metafile.size < @options[:chunk_size]
        result = client.upload metafile.path, File.read(metafile.local_path), mode: :overwrite
      else
        while metafile.upload_session[:offset] < metafile.size
          chunk = File.read metafile.local_path, @options[:chunk_size], metafile.upload_session[:offset]
          if metafile.upload_session[:offset] == 0
            metafile.upload_session = client.upload_session_start(chunk).to_hash.with_indifferent_access
          elsif metafile.upload_session[:offset] + @options[:chunk_size] < metafile.size
            client.upload_session_append_v2 metafile.upload_session, chunk
            metafile.upload_session[:offset] += @options[:chunk_size]
          else
            result = client.upload_session_finish metafile.upload_session, { mode: :overwrite, path: metafile.path }, chunk
            metafile.upload_session[:offset] = metafile.size
          end
        end
      end
      metafile.update(revision: result.rev) if result.is_a? DropboxApi::Metadata::File
    end
  end

private

  def _client
    DropboxApi::Client.new(@storage.access_token)
  end

  def max_number_of_threads
    10
  end

  def up_to_date?(client, metafile)
    entries(client, metafile.folder_path).select do |entry|
      entry.name == metafile.name && entry.size == metafile.size
    end.present?
  end

  def entries(client, path)
    @semaphore.synchronize do
      if @entries
        @entries
      else
        begin
          result = client.list_folder path
          @entries = result.entries
          while result.has_more?
            result = client.list_folder_continue result.cursor
            @entries += result.entries
          end
          @entries
        rescue DropboxApi::Errors::NotFoundError
          @entries = []
        end
      end
    end
  end

  def retryable_failure?(error)
    error.is_a?(DropboxApi::Errors::BasicError) && !manageable_failure?(error)
  end

  def manageable_failure?(error)
    (error.class == DropboxApi::Errors::UploadWriteFailedError && error.message.match(/\Apath\/insufficient_space/)) ||
    (error.class == DropboxApi::Errors::HttpError && error.message.match(/invalid_access_token/))
  end

  def manage_failure(error)
    if (error.class == DropboxApi::Errors::UploadWriteFailedError && error.message.match(/\Apath\/insufficient_space/))
      @storage.disable
      NotifyDropboxError.new(@storage.user, 'dropbox_insufficient_space').execute
    elsif (error.class == DropboxApi::Errors::HttpError && error.message.match(/invalid_access_token/))
      @storage.reset_access_token
      NotifyDropboxError.new(@storage.user, 'dropbox_invalid_access_token').execute
    end
  end
end
