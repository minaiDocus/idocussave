# -*- encoding : UTF-8 -*-
class Journal::UpdateRelation
  def initialize(journal)
    @journal = journal
  end

  def execute
    FileImport::Ibizabox.update_folders(@journal.user)
    if @journal.destroyed?
      @journal.retrievers.update_all(journal_id: nil)
    else
      @journal.retrievers.where.not(journal_name: [@journal.name]).update_all(journal_name: @journal.name)
      @journal.user.retrievers.where(journal_name: @journal.name, journal_id: nil).update_all(journal_id: @journal.id)
    end
  end
end
