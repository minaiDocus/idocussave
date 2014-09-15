# -*- encoding : UTF-8 -*-
class EventCreateService
  def add_journal(journal, user, requester, options={})
    event = Event.new
    event.user              = requester
    event.organization      = user.organization
    event.target_type       = 'account_book_type/user'
    event.target_id         = "#{journal.id}/#{user.id}"
    event.target_name       = "#{journal.name}/#{user.code}"
    event.action            = 'add'
    event.target_attributes = journal.attributes.dup
    event.path              = options[:path]
    event.ip_address        = options[:ip_address]
    event.save
  end

  def remove_journal(journal, user, requester, options={})
    event = Event.new
    event.user              = requester
    event.organization      = user.organization
    event.target_type       = 'account_book_type/user'
    event.target_id         = "#{journal.id}/#{user.id}"
    event.target_name       = "#{journal.name}/#{user.code}"
    event.action            = 'remove'
    event.target_attributes = journal.attributes.dup
    event.path              = options[:path]
    event.ip_address        = options[:ip_address]
    event.save
  end

  def journal_update(journal, user, changes, requester, options={})
    if changes.present?
      journal_name = changes['name'].try(:[], 0) || journal.name
      event = Event.new
      event.user              = requester
      event.organization      = user.organization
      event.target_type       = 'account_book_type/user'
      event.target_id         = "#{journal.id}/#{user.id}"
      event.target_name       = "#{journal_name}/#{user.code}"
      event.action            = 'update'
      event.target_attributes = changes
      event.path              = options[:path]
      event.ip_address        = options[:ip_address]
      event.save
    end
  end
end
