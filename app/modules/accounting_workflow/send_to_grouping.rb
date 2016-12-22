class AccountingWorkflow::SendToGrouping
  def initialize(temp_document)
    @temp_document = temp_document
  end


  def execute
    @temp_document.scanned? ? copy : split

    only_allows_read

    @temp_document.bundling
  end


  def path
    @path ||= AccountingWorkflow.grouping_dir.join(@temp_document.delivery_type + 's')
  end


  def basename
    @temp_document.name_with_position
  end


  private


  def copy
    filepath = FileStoragePathUtils.path_for_object(@temp_document)

    FileUtils.cp filepath, path.join(basename + '.pdf')
  end


  def split
    filepath = FileStoragePathUtils.path_for_object(@temp_document)

    Pdftk.new.burst filepath, path, basename, AccountingWorkflow::TempPackProcessor::POSITION_SIZE
  end


  def only_allows_read
    POSIX::Spawn.system("chmod 644 #{path.join('*.pdf')}")
  end
end
