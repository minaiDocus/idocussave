module CreateEvent
  def self.add_journal(journal, user, requester, options = {})
    event = Event.new
    event.user              = requester
    event.path              = options[:path]
    event.action            = 'add'
    event.target_id         = "#{journal.id}/#{user.id}"
    event.target_type       = 'account_book_type/user'
    event.target_name       = "#{journal.name}/#{user.code}"
    event.ip_address        = options[:ip_address]
    event.organization      = user.organization
    event.target_attributes = journal.attributes.dup
    event.save
  end

  def self.remove_journal(journal, user, requester, options = {})
    event = Event.new
    event.user              = requester
    event.path              = options[:path]
    event.action            = 'remove'
    event.target_id         = "#{journal.id}/#{user.id}"
    event.target_type       = 'account_book_type/user'
    event.target_name       = "#{journal.name}/#{user.code}"
    event.ip_address        = options[:ip_address]
    event.organization      = user.organization
    event.target_attributes = journal.attributes.dup
    event.save
  end

  def self.journal_update(journal, user, changes, requester, options = {})
    if changes.present?
      journal_name = changes['name'].try(:[], 0) || journal.name

      event = Event.new
      event.user              = requester
      event.path              = options[:path]
      event.action            = 'update'
      event.target_id         = "#{journal.id}/#{user.id}"
      event.target_type       = 'account_book_type/user'
      event.target_name       = "#{journal_name}/#{user.code}"
      event.ip_address        = options[:ip_address]
      event.organization      = user.organization
      event.target_attributes = changes
      event.save
    end
  end
end
