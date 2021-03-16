class EmailedDocument::Attachment
  attr_accessor :file_path, :file_name

  def initialize(original, file_name, user)
    @original  = original
    @file_name = file_name
    @user      = user
    @file_path = get_file_path
    @dir_temp = []
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
    printable? && !corrupted?
  end

  def original_extension
    File.extname(name).downcase
  end

  def protected?
    if @protected.nil?
      @protected = DocumentTools.protected? processed_file_path
    else
      @protected
    end
  end

  # syntactic sugar ||= does not store false/nil value
  def printable?
    if @printable.nil?
      @printable = DocumentTools.printable? processed_file_path
    else
      @printable
    end
  end

    # syntactic sugar ||= does not store false/nil value
  def corrupted?
    if @corrupted.nil?
      @corrupted = DocumentTools.corrupted? processed_file_path
    else
      @corrupted
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
    @fingerprint ||= DocumentTools.checksum processed_file_path
  end

  def valid?(without_self=false)
    valid_size? && valid_content? && valid_pages_number? && unique?(without_self)
  end


  def dir
    CustomUtils.mktmpdir('attachment_1', nil, false) do |dir|
      @dir = dir
    end
  end

  def dir_2
    CustomUtils.mktmpdir('attachment_2', nil, false) do |dir|
      @dir_2 = dir
    end
  end

  def clean_dir
    FileUtils.remove_entry(@dir, true) if @dir
    FileUtils.remove_entry(@dir_2, true) if @dir_2
  end

  def processed_file_path
    if @temp_file_path
      @temp_file_path
    else
      @temp_file_path = PdfIntegrator.new(File.open(@file_path, 'r'), File.join(dir_2, @file_name), 'Attachment').processed_file.path
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