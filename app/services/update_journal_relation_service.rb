# -*- encoding : UTF-8 -*-
# Updates journal relation with fiduceo retrievers
class UpdateJournalRelationService
  def initialize(journal)
    @journal = journal
  end


  def execute
    if @journal.destroyed?
      @journal.fiduceo_retrievers.update_all(journal_id: nil)
    else
      @journal.fiduceo_retrievers.where.not(journal_name: [@journal.name]).update_all(journal_name: @journal.name)
      @journal.user.fiduceo_retrievers.where(journal_name: @journal.name, journal_id: nil).update_all(journal_id: @journal.id)
    end
  end
end
