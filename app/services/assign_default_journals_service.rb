# -*- encoding : UTF-8 -*-
class AssignDefaultJournalsService
  def initialize(user, collaborator, request=nil)
    @user         = user
    @organization = @user.organization
    @collaborator = collaborator
    @request      = request
  end

  def execute
    journals.map do |journal|
      new_journal = copy_journal(journal)
      create_event(new_journal)
      new_journal
    end
  end

private

  def copy_journal(journal)
    new_journal = journal.dup
    new_journal.user         = nil
    new_journal.organization = nil
    new_journal.is_default   = nil
    new_journal._slugs       = []
    @user.account_book_types << new_journal
    new_journal.save
    new_journal
  end

  def create_event(journal)
    params = [journal, @user, @collaborator]
    params << { path: @request.path, ip_address: @request.remote_ip } if @request
    EventCreateService.new.add_journal(*params)
  end

  def current_journal_names
    @current_journal_names ||= @user.account_book_types.map(&:name)
  end

  def journals
    result = @organization.account_book_types.default
    result = result.where(:name.nin => current_journal_names) if current_journal_names.present?
    if is_preassignment_authorized?
      js = result.where(:entry_type.gt => 0).asc([:entry_type, :name]).entries
      js += result.where(entry_type: 0).asc(:name).entries
      js.take available_slot
    else
      result.not_compta_processable.asc(:name).limit(available_slot)
    end
  end

  def available_slot
    @user.options.max_number_of_journals - @user.account_book_types.size
  end

  def is_preassignment_authorized?
    @user.options.is_preassignment_authorized
  end
end
