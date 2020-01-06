class CustomActiveStorageObject
  def initialize(object, attachment)
    @object    = object
    @attachment = attachment
    @base_url  = @object.class::ATTACHMENTS_URLS[attachment.to_s]
  end

  def attach(io, filename)
    if as_attached.attached?
      begin
        FileUtils.rm path, force: true
      rescue
        nil
      end

      as_attached.purge
    end

    as_attached.attach(io: io, filename: filename)
  end

  def path(style = '')
    if as_attached.attached?
      generate_file style
      @base_path
    else
      pc_attached.path(style.to_sym)
    end
  end

  def url(style = '')
    if as_attached.attached?
      return nil unless @base_url
      @base_url.gsub(':id', @object.id.to_s)
               .gsub(':style', style.to_s)
               .gsub(':filename', @object.try(:filename).to_s)
               .gsub(':basename', @object.try(:basename).to_s)
               .gsub(':extension', @object.try(:extension).to_s)
    else
      pc_attached.url(style.to_sym)
    end
  end

  def size
    if as_attached.attached?
      as_attached.blob.byte_size
    else
      target_file_size = @attachment.to_s.gsub('cloud_', '') + '_file_size'
      @object.send(target_file_size.to_sym)
    end
  end

  def filename
    if as_attached.attached?
      as_attached.filename.sanitized.gsub('-', '_')
    else
      target_file_name = @attachment.to_s.gsub('cloud_', '') + '_file_name'
      @object.send(target_file_name.to_sym)
    end
  end

  private

  #active storage attached
  def as_attached
    @object.send(@attachment.to_sym)
  end

  #paper clip attached
  def pc_attached
    @object.send(@attachment.to_s.gsub('cloud_', '').to_sym)
  end

  def generate_file(style = '')
    begin
      if style.to_s == 'medium' || style.to_s == 'thumb'
        size_limit = if style.to_s == 'medium'
                      [92, 133]
                     else
                      [46, 67]
                     end
        #TODO: resize limit doesn't work
        blob = as_attached.preview(resize_to_limit: size_limit).processed.image
        dir = "#{Rails.root}/tmp/#{@object.class.name}/#{Time.now.strftime('%Y%m%d')}/#{@object.id}/#{style.to_s}/"
        tmp_file_path = File.join(dir, Time.now.strftime('%Y%m%d') + '.png')
      else
        blob = as_attached
        dir = "#{Rails.root}/tmp/#{@object.class.name}/#{Time.now.strftime('%Y%m%d')}/#{@object.id}/"
        tmp_file_path = File.join(dir, filename)
      end

      unless File.exist? tmp_file_path
        dir = FileUtils.makedirs(dir)
        FileUtils.chmod(0755, dir)

        FileUtils.delay_for(1.hours, queue: :low).remove_dir(dir, true)

        tmp_file = File.open(tmp_file_path, 'wb')
        tmp_file.write blob.download
        tmp_file.close
      end

      @base_path = tmp_file_path
    rescue => e
      @base_path = nil
    end
  end
end