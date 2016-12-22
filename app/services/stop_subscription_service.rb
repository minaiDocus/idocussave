# -*- encoding : UTF-8 -*-
# Disable user services when a subscription is stoped
class StopSubscriptionService
  def initialize(user, close_now = false)
    @user = user
    @close_now = close_now == '1' ? true : false
  end


  def execute
    period = @user.subscription.find_period(Time.now)

    # Disable period and disable user
    if period
      if @close_now
        @user.inactive_at = period.start_at

        period.destroy
      else
        @user.inactive_at = period.start_at + period.duration.month
      end
    else
      @user.inactive_at = Time.now
    end

    # Revoke authorization
    @user.email_code = nil
    @user.is_fiduceo_authorized  = false
    @user.is_dematbox_authorized = false
    @user.account_number_rules   = []
    @user.save

    @user.subscription.update_attributes(start_at: nil, end_at: nil)


    # Revoke authorizations stored in options
    @user.options.max_number_of_journals       = 0
    @user.options.is_preassignment_authorized = false
    @user.options.save

    # Disable external services

    RemoveFiduceoService.new(@user.id.to_s).execute

    @user.dematbox.try(:unsubscribe)

    @user.external_file_storage.try(:destroy)

    DropboxImport.changed(@user.reload)


    # Remove composition
    if @user.composition.present? && File.exist?("#{Rails.root}/files/#{Rails.env}/compositions/#{@user.composition.id}")
      system("rm -r #{Rails.root}/files/#{Rails.env}/compositions/#{@user.composition.id}")
    end
    @user.composition.try(:destroy)

    @user.debit_mandate.try(:destroy)

    true
  end
end
