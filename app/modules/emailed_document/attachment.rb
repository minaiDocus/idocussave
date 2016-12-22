class EmailedDocument::Attachment
  attr_accessor :file_path, :file_name

  def initialize(original, file_name)
    @original  = original
    @file_name = file_name
    @file_path = get_file_path
    DocumentTools.remove_pdf_security(@file_path, @file_path) if is_printable_only?
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


  # syntactic sugar ||= does not store false/nil value
  def printable?
    if @printable.nil?
      @printable = DocumentTools.printable? @file_path
    else
      @printable
    end
  end


  def pages_number
    DocumentTools.pages_number(@file_path)
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

      @is_printable_only = DocumentTools.is_printable_only? @file_path
    end
  end


  def valid?
    valid_size? && valid_content? && valid_pages_number?
  end


  def dir
    @dir ||= Dir.mktmpdir
  end


  def clean_dir
    FileUtils.remove_entry @dir if @dir
  end

  private

  def get_file_path
    f = File.new(File.join(dir, @file_name), 'w')
    f.write @original.body.decoded.force_encoding('UTF-8')
    f.close

    f.path
  end
end
