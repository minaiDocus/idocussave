class IbizaClientCallback
  def initialize(ibiza, access_token)
    @ibiza = ibiza
    @access_token = access_token
  end

  def after_run(response)
    return if response.success?
    return unless response.message.is_a?(Hash)
    return unless response.message.dig('error', 'details').try(:match, /Invalid directory authentication/)

    UniqueJobs.for "IbizaClientCallback-#{@ibiza.id}", 1.minute do
      return if notified?
      disable_invalid_access_token
      notify_disabled
    end
  end

  private

  def disable_invalid_access_token
    if @ibiza.access_token == @access_token
      @ibiza.state = 'invalid'
    else @ibiza.access_token_2 == @access_token
      @ibiza.state_2 = 'invalid'
    end
    @ibiza.save
  end

  def notified?
    return unless @ibiza.organization.leader
    @ibiza.organization.leader.notifications.where(notice_type: 'ibiza_invalid_access_token').where('created_at > ?', 1.day.ago).exists?
  end

  def notify_disabled
    notification = Notification.new
    notification.user        = @ibiza.organization.leader
    notification.notice_type = 'ibiza_invalid_access_token'
    notification.title       = 'Compte iBiza déconnecté'
    notification.message     = "Votre compte iBiza n'est plus connectée, merci de le reconfigurer, s'il vous plaît."
    notification.url         = Rails.application.routes.url_helpers.account_organization_url(
                                 @ibiza.organization, { tab: 'ibiza' }.merge(ActionMailer::Base.default_url_options))
    notification.save
    NotifyWorker.perform_async(notification.id)
  end
end