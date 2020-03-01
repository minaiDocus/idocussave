class Storage::Metafile
  attr_accessor :upload_session

  def initialize(remote_file, path_pattern, number, total)
    @remote_file    = remote_file
    @number         = number
    @total          = total
    @path_pattern   = path_pattern
    @upload_session = { session_id: nil, offset: 0 }
  end

  def folder_path
    @folder_path ||= ExternalFileStorage.delivery_path(@remote_file, @path_pattern)
  end

  def path
    @path ||= File.join(folder_path.to_s, name.to_s).to_s
  end

  def name
    return @name if @name
    @name = @remote_file.name
    @name.sub!('%', '_') if @remote_file.service_name == RemoteFile::MY_COMPANY_FILES
    @name
  end

  def description
    @description ||= "[#{@remote_file.service_name}]" +
      "[#{@remote_file.receiver_info}]" +
      "[#{"%0.#{@total.to_s.size}d" % @number}/#{@total}]" +
      "[#{ActionController::Base.helpers.number_to_human_size(size)}]" +
      " \"#{path}\""
  end

  def size
    @size ||= @remote_file.local_size
  end

  def fingerprint
    @remote_file.remotable.try(:content_fingerprint) || DocumentTools.checksum(@remote_file.temp_path)
  end

  def method_missing(name, *args, &block)
    @remote_file.send(name, *args, &block)
  end
end
