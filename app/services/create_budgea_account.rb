# -*- encoding : UTF-8 -*-
class CreateBudgeaAccount
  def self.execute(user)
    user.options.with_lock(timeout: 10, retry_sleep: 1) do
      unless user.budgea_account.try(:access_token).present?
        client = Budgea::Client.new
        result = client.create_user
        if client.response.code == 200
          budgea_account = BudgeaAccount.new
          budgea_account.user = user
          budgea_account.access_token = result['access_token']
          budgea_account.save
          client.get_profiles
          if client.response.code == 200
            budgea_account.identifier = client.user_id
          else
            # TODO handle failure
          end
          budgea_account.save
        else
          # TODO handle failure
        end
      end
    end
    user.budgea_account.present?
  end
end
