# -*- encoding : UTF-8 -*-
class PonctualScripts::Archive::RenewBudgeaAccessToken
  class << self
    def for_all
      puts "Total BudgeaAccount : #{BudgeaAccount.count}"
      BudgeaAccount.each do |account|
        new(account).execute
      end
    end
  end

  def initialize(account)
    @account = account
  end

  def execute
    puts @account.user.code
    client = Budgea::Client.new @account.access_token
    result = client.get_new_access_token @account.identifier
    if client.response.status == 200
      if client.delete_access_token
        @account.update(access_token: result['token'])
      else
        puts "\tCannot delete old access token for user #{@account.user.code}."
      end
    else
      puts "\tCannot get new access token for user #{@account.user.code}."
    end
  end
end
