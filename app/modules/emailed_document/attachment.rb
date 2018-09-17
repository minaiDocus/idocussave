class EmailedDocument::Attachment
  attr_accessor :file_path, :file_name

  def initialize(original, file_name, user)
    @original  = original
    @file_name = file_name
    @user      = user
    @file_path = get_file_path
    DocumentTools.remove_pdf_security(processed_file_path, processed_file_path) if is_printable_only?
  end


  def name
    @name ||= @original.filename
  end

  def size
    @size ||= @original.body.decoded.length
  end


  def valid_size?
    size <= 5.megabytes
  end


  def valid_content?
    printable?
  end

  def original_extension
    File.extname(name).downcase
  end

  # syntactic sugar ||= does not store false/nil value
  def printable?
    if @printable.nil?
      @printable = DocumentTools.printable? processed_file_path
    else
      @printable
    end
  end


  def pages_number
    DocumentTools.pages_number(processed_file_path)
  rescue
    0
  end


  def valid_pages_number?
    pages_number <= 100
  end


  # syntactic sugar ||= does not store false/nil value
  def is_printable_only?
    if @is_printable_only_set
      @is_printable_only
    else
      @is_printable_only_set = true

      @is_printable_only = DocumentTools.is_printable_only? processed_file_path
    end
  end

  def unique?(without_self=false)
    if without_self
      TempDocument.where('user_id = ? AND (original_fingerprint = ? OR content_fingerprint = ? OR raw_content_fingerprint = ?)', @user.id, fingerprint, fingerprint, fingerprint).count > 1 ? false : true
    else
      TempDocument.where('user_id = ? AND (original_fingerprint = ? OR content_fingerprint = ? OR raw_content_fingerprint = ?)', @user.id, fingerprint, fingerprint, fingerprint).first ? false : true
    end
  end

  def fingerprint
    @fingerprint ||= DocumentTools.checksum @file_path
  end

  def valid?(without_self=false)
    valid_size? && valid_content? && valid_pages_number? && unique?(without_self)
  end


  def dir
    @dir ||= Dir.mktmpdir
  end


  def clean_dir
    FileUtils.remove_entry @dir if @dir
  end

  def processed_file_path
    if @temp_file_path
      @temp_file_path
    else
      @temp_file_path = if original_extension != '.pdf'
        geometry = Paperclip::Geometry.from_file @file_path

        tmp_file_path = @file_path
        if geometry.height > 2000 || geometry.width > 2000
          tmp_file_path = File.join(dir, "resized_#{File.basename(@file_path)}")
          DocumentTools.resize_img(@file_path, tmp_file_path)
        end

        DocumentTools.to_pdf(tmp_file_path, File.join(dir, @file_name))
        File.join(dir, @file_name)
      else
        @file_path
      end
    end
  end

  private

  def get_file_path
    filename = File.basename(@file_name, '.pdf') + original_extension
    f = File.new(File.join(dir, filename), 'w')
    f.write @original.body.decoded.force_encoding('UTF-8')
    f.close
    f.path
  end
end
