# -*- encoding : UTF-8 -*-
class CreateBudgeaAccount
  def self.execute(user)
    new(user).execute
  end

  def initialize(user)
    @user = user
  end

  def execute
    unless @user.budgea_account.try(:persisted?)
      result = try_request { client.create_user }
      if client.response.code == 200
        budgea_account = BudgeaAccount.new
        budgea_account.user = @user
        budgea_account.access_token = result
        profiles = try_request { client.get_profiles }
        if client.response.code == 200
          budgea_account.identifier = profiles.first['id_user']
        else
          message = "[#{@user.code}] Get identifier<br/>[#{client.response.code}] : #{client.response.body}"
          notify_failure(message)
        end
        budgea_account.save
      else
        message = "[#{@user.code}] Create user<br/>[#{client.response.code}] : #{client.response.body}"
        notify_failure(message)
      end
    end
    @user.budgea_account.try(:persisted?)
  end

private

  def client
    @client ||= Budgea::Client.new
  end

  def try_request(&block)
    result = nil
    3.times do |i|
      sleep(i) if i > 0
      result = yield
      break if client.response.code == 200
    end
    result
  end

  def notify_failure(message)
    addresses = Array(Settings.notify_errors_to)
    if addresses.size > 0
      NotificationMailer.notify(addresses, '[iDocus] Erreur lors de la création de l\'utilisateur Budgea', message).deliver
    end
  end
end
