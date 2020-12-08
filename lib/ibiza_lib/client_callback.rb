module IbizaLib
  class ClientCallback
    def initialize(ibiza, access_token)
      @ibiza = ibiza
      @access_token = access_token
    end

    def after_run(response)
      return if response.success?
      return unless response.message.is_a?(Hash)
      return unless response.message.dig('error', 'details').try(:match, /Invalid directory authentication/)

      UniqueJobs.for "IbizaClientCallback-#{@ibiza.id}", 1.minute do
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
      @ibiza.save if @ibiza.changed?
    end

    def notified?(user)
      user.notifications.where(notice_type: 'ibiza_invalid_access_token').where('created_at > ?', 1.day.ago).exists?
    end

    def notify_disabled
      @ibiza.try(:owner).try(:organization).try(:admins).each do |admin|
        next if notified?(admin)

        Notifications::Notifier.new.create_notification({
          url: Rails.application.routes.url_helpers.account_organization_url(@ibiza.try(:owner).try(:organization), { tab: 'ibiza' }.merge(ActionMailer::Base.default_url_options)),
          user: admin,
          notice_type: 'ibiza_invalid_access_token',
          title: 'Compte iBiza déconnecté',
          message: "Votre compte iBiza n'est plus connectée, merci de le reconfigurer, s'il vous plaît."
        }, true)
      end
    end
  end
end