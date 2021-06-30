# -*- encoding : UTF-8 -*-
class Subscription::Evaluate
  def initialize(subscription, requester = nil, request = nil)
    @subscription = subscription
    @customer     = subscription.user
    @requester    = requester
    @request      = request
  end

  def execute
    @subscription.set_start_date_and_end_date

    period = @subscription.current_period
    update_max_number_of_journals

    period.is_active?(:ido_x) ? unauthorize_dematbox : authorize_dematbox

    if period.is_active?(:ido_classique) || period.is_active?(:ido_micro) || period.is_active?(:ido_mini) || period.is_active?(:ido_nano)
      authorize_upload
    else
      unauthorize_upload
    end

    if period.is_active?(:retriever_option) || period.is_active?(:ido_micro)
      authorize_retriever
    else
      unauthorize_retriever
    end

    if period.is_active?(:pre_assignment_option) && ( period.is_active?(:ido_classique) || period.is_active?(:ido_mini) )
      authorize_pre_assignment
    elsif period.is_active?(:ido_micro) || period.is_active?(:ido_nano) || ( (period.is_active?(:retriever_option) || period.is_active?(:digitize_option)) && !( period.is_active?(:ido_classique) || period.is_active?(:ido_mini) ))
      authorize_pre_assignment
    else
      unauthorize_pre_assignment
    end
    

    Journal::AssignDefault.new(@customer, @requester, @request).execute if @requester
  end

private

  def authorize_dematbox
    @customer.update_attribute(:is_dematbox_authorized, true) unless @customer.is_dematbox_authorized
  end

  def unauthorize_dematbox
    @customer.update_attribute(:is_dematbox_authorized, false) if @customer.is_dematbox_authorized
    @customer.dematbox.delay(queue: :high).unsubscribe if @customer.dematbox.try(:is_configured)
  end

  def authorize_retriever
    @customer.options.update_attribute(:is_retriever_authorized, true) unless @customer.options.is_retriever_authorized
  end

  def unauthorize_retriever
    if @customer.options.is_retriever_authorized
      @customer.options.update_attribute(:is_retriever_authorized, false)
      Retriever::Remove.delay.execute(@customer.id.to_s) if @customer.budgea_account.present?
    end
  end

  def authorize_pre_assignment
    unless @customer.options.is_preassignment_authorized
      @customer.options.update_attribute(:is_preassignment_authorized, true)
      Journal::AssignDefault.new(@customer, @requester, @request).execute if @requester
      FileImport::Dropbox.changed(@customer)
    end
  end

  def unauthorize_pre_assignment
    if @customer.options.is_preassignment_authorized
      @customer.options.update_attribute(:is_preassignment_authorized, false)
      @customer.account_book_types.pre_assignment_processable.each do |journal|
        journal.reset_compta_attributes
        changes = journal.changes
        if journal.save
          params = [journal, @customer, changes, @requester.try(:user)]
          CreateEvent.journal_update(*params)
        end
      end
    end
  end

  def authorize_upload
    @customer.options.update_attribute(:is_upload_authorized, true) unless @customer.options.is_upload_authorized
  end

  def unauthorize_upload
    @customer.options.update_attribute(:is_upload_authorized, false) if @customer.options.is_upload_authorized
  end

  def update_max_number_of_journals
    @customer.options.update_attribute(:max_number_of_journals, @subscription.number_of_journals) unless @customer.options.max_number_of_journals == @subscription.number_of_journals
  end
end
