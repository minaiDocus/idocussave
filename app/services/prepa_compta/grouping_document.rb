# -*- encoding : UTF-8 -*-
class PrepaCompta::GroupingDocument
  def self.execute
    TempPack.bundle_needed.not_recently_updated.asc(:updated_at).sum do |temp_pack|
      temp_pack.temp_documents.bundle_needed.by_position.sum do |temp_document|
        new(temp_document).execute
        1
      end
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
    @path ||= PrepaCompta.grouping_dir.join(@temp_document.delivery_type + 's')
  end

  def basename
    @temp_document.name_with_position
  end

private

  def copy
    FileUtils.cp @temp_document.content.path, path.join(basename + '.pdf')
  end

  def split
    Pdftk.new.burst @temp_document.content.path, path, basename, DocumentProcessor::POSITION_SIZE
  end

  def only_allows_read
    POSIX::Spawn::system("chmod 644 #{path.join('*.pdf')}")
  end
end
