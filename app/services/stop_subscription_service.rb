# -*- encoding : UTF-8 -*-
class StopSubscriptionService
  def initialize(user, close_now=false)
    @user = user
    @close_now = close_now == '1' ? true : false
  end

  def execute
    period = @user.subscription.find_period(Time.now)
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
    @user.email_code             = nil
    @user.is_fiduceo_authorized  = false
    @user.is_dematbox_authorized = false
    @user.save
    @user.options.max_number_of_journals      = 0
    @user.options.is_preassignment_authorized = false
    @user.options.save
    RemoveFiduceoService.new(@user.id.to_s).delay.execute
    @user.dematbox.try(:unsubscribe)
    @user.external_file_storage.try(:destroy)
    if @user.composition.present? && File.exists?("#{Rails.root}/files/#{Rails.env}/compositions/#{@user.composition.id}")
      system("rm -r #{Rails.root}/files/#{Rails.env}/compositions/#{@user.composition.id}")
    end
    @user.composition.try(:destroy)
    @user.debit_mandate.try(:destroy)
    @user.valid?
  end
end
