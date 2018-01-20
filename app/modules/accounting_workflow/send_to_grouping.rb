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
    FileUtils.cp @temp_document.content.path, path.join(basename + '.pdf')
  end


  def split
    Pdftk.new.burst @temp_document.content.path, path, basename, AccountingWorkflow::TempPackProcessor::POSITION_SIZE
  end


  def only_allows_read
    POSIX::Spawn.system("chmod 644 #{path.join('*.pdf')}")
  end
end
