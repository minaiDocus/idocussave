class FileImport::Dropbox::Folder
  attr_accessor :path, :is_present

  def initialize(path, is_present)
    @path = path
    @is_present = is_present
  end

  def created
    @is_present = true
  end

  def exist?
    @is_present == true
  end

  def to_be_created
    @is_present = false
  end

  def to_be_created?
    @is_present == false
  end

  def to_be_destroyed
    @is_present = nil
  end

  def to_be_destroyed?
    @is_present.nil?
  end
end
