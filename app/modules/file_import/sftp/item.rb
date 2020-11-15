class FileImport::Sftp::Item
  attr_reader :name, :children, :is_present
  attr_accessor :parent, :customer, :journal

  def initialize(name, is_a_folder=true, is_present=true)
    @name = name
    @is_a_folder = is_a_folder
    @is_present = is_present
    @children = []
  end

  def add(item)
    item.parent = self
    @children << item
  end

  def remove(item)
    item.parent = nil
    @children -= [item]
  end

  def orphan
    parent.remove self
  end

  def path
    result = (parent_names + [@name]).join('/')
    result == '' ? '/' : result
  end

  def parent_names
    item = self
    result = []
    while item.parent.present?
      result << item.parent.name
      item = item.parent
    end
    result.reverse
  end

  def folder?
    @is_a_folder
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
