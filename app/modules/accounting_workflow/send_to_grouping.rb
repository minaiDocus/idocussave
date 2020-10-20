class AccountingWorkflow::SendToGrouping

  def self.process(temp_doc_id)
    UniqueJobs.for "SendToGrouping-#{temp_doc_id}" do
      temp_document = TempDocument.find temp_doc_id
      AccountingWorkflow::SendToGrouping.new(temp_document).execute if temp_document.bundle_needed?
    end
  end

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
    FileUtils.cp @temp_document.cloud_content_object.path, path.join(basename + '.pdf')
  end


  def split
    Pdftk.new.burst @temp_document.cloud_content_object.path, path, basename, AccountingWorkflow::TempPackProcessor::POSITION_SIZE

    splited_pages = `ls '#{path.to_s + '/' + basename.to_s}'* | wc -l`.strip.to_i

    if @temp_document.pages_number != splited_pages
      log_document = {
        name: "GroupingDocument - Test",
        error_group: "[grouping-document] Grouping pages verificator",
        erreur_type: "Grouping pages verificator",
        date_erreur: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
        more_information: {
          temp_document: @temp_document.id,
          position: @temp_document.position,
          path: path,
          base_name: basename,
          pages_number: @temp_document.pages_number,
          splited_page: splited_pages
        }
      }

      ErrorScriptMailer.error_notification(log_document).deliver
    end
  end


  def only_allows_read
    POSIX::Spawn.system("chmod 644 #{path.join('*.pdf')}")
  end
end
