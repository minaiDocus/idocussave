# -*- encoding : UTF-8 -*-
class RemoveRetrieverService
  def initialize(object, notify_error=true)
    if object.is_a? String
      @user = User.find object
    else
      @user = object
    end
    @notify_error = notify_error
  end

  def execute
    if @user.budgea_account.present?
      @user.temp_documents.wait_selection.destroy_all
      @user.retrievers.each(&:destroy)
      client = Budgea::Client.new(@user.budgea_account.access_token)
      notify unless client.destroy_user
    end
  end

private

  def notify
    if @notify_error
      addresses = Array(Settings.first.notify_errors_to)
      if addresses.size > 0
        NotificationMailer.notify(addresses, "[iDocus][#{Rails.env}] Impossible de supprimer le service Automate pour le client #{@user.code}", '-').deliver
      end
    end
  end
end
