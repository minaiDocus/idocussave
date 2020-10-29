# -*- encoding : UTF-8 -*-
class Retriever::Remove
  def self.execute(user_id)
    new(user_id).execute
  end

  def initialize(object, notify_error=true)
    if object.is_a? String
      @user = User.find object
    else
      @user = object
    end
    @notify_error = notify_error
  end

  def execute
    @user.temp_documents.wait_selection.destroy_all
    @user.retrievers.each do |retriever|
      Retriever::DestroyBudgeaConnection.disable_accounts(retriever.id) if retriever.destroy_connection
    end
    if @user.budgea_account.present?
      client = Budgea::Client.new(@user.budgea_account.access_token)
      if client.destroy_user
        @user.budgea_account.destroy
      else
        notify
      end
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
