# -*- encoding : UTF-8 -*-
class EvaluateSubscription
  def initialize(subscription, requester=nil, request=nil)
    @subscription = subscription
    @customer     = subscription.user
    @requester    = requester
    @request      = request
  end

  def execute
    update_max_number_of_journals
    if @subscription.is_annual_package_active
      unauthorize_dematbox
      authorize_fiduceo
      authorize_pre_assignment
      authorize_upload
    else
      if @subscription.is_basic_package_active || @subscription.is_mail_package_active || @subscription.is_scan_box_package_active
        authorize_upload
      else
        unauthorize_upload
      end
      @subscription.is_scan_box_package_active  ? authorize_dematbox       : unauthorize_dematbox
      @subscription.is_retriever_package_active ? authorize_fiduceo        : unauthorize_fiduceo
      @subscription.is_pre_assignment_active    ? authorize_pre_assignment : unauthorize_pre_assignment
    end
    AssignDefaultJournalsService.new(@customer, @requester, @request).execute if @requester
  end

private

  def authorize_dematbox
    @customer.update_attribute(:is_dematbox_authorized, true) unless @customer.is_dematbox_authorized
  end

  def unauthorize_dematbox
    @customer.update_attribute(:is_dematbox_authorized, false) if @customer.is_dematbox_authorized
    @customer.dematbox.delay(priority: 1).unsubscribe if @customer.dematbox.try(:is_configured)
  end

  def authorize_fiduceo
    @customer.update_attribute(:is_fiduceo_authorized, true) unless @customer.is_fiduceo_authorized
  end

  def unauthorize_fiduceo
    if @customer.is_fiduceo_authorized
      @customer.update_attribute(:is_fiduceo_authorized, false)
      RemoveFiduceoService.new(@customer.id.to_s).delay.execute if @customer.fiduceo_id.present?
    end
  end

  def authorize_pre_assignment
    unless @customer.options.is_preassignment_authorized
      @customer.options.update_attribute(:is_preassignment_authorized, true)
      AssignDefaultJournalsService.new(@customer, @requester, @request).execute if @requester
      DropboxImportFolder.changed(@customer)
    end
  end

  def unauthorize_pre_assignment
    if @customer.options.is_preassignment_authorized
      @customer.options.update_attribute(:is_preassignment_authorized, false)
      @customer.account_book_types.pre_assignment_processable.each do |journal|
        journal.reset_compta_attributes
        changes = journal.changes
        if journal.save
          params = [journal, @customer, changes, @requester]
          EventCreateService.new.journal_update(*params)
        end
      end
    end
  end

  def authorize_upload
    unless @customer.options.is_upload_authorized
      @customer.options.update_attribute(:is_upload_authorized, true)
    end
  end

  def unauthorize_upload
    if @customer.options.is_upload_authorized
      @customer.options.update_attribute(:is_upload_authorized, false)
    end
  end

  def update_max_number_of_journals
    unless @customer.options.max_number_of_journals == @subscription.number_of_journals
      @customer.options.update_attribute(:max_number_of_journals, @subscription.number_of_journals)
    end
  end
end