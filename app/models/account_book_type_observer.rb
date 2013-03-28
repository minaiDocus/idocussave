class AccountBookTypeObserver < Mongoid::Observer
  def after_create(journal)
    request = Request.new
    request.requestable = journal
    request.no_sync = true
    request.save
  end

  def after_save(journal)
    if journal.persisted?
      journal.reload
      journal.request.sync_with_requestable!
    end
  end
end