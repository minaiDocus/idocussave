class PonctualScripts::BudgeaTokenTester < PonctualScripts::PonctualScript
  def self.execute(budgea_accounts)
    new({accounts: budgea_accounts}).run
  end

  private

  def execute
    accounts = @options[:accounts]
    count = 0

    accounts.each_slice(50) do |account_slices|
      count += 1

      file_path = Rails.root.join('files', "budgea_token_tester_#{count}.csv")
      file = File.open(file_path, 'w')
      file.write("user_code; budgea_id; token; connexion\n")

      account_slices.each_with_index do |account, index|
        user = account.user
        next unless user.active?

        token = account.access_token
        client = Budgea::Client.new(token)
        result = client.get_all_connections

        file.write("#{user.code.to_s}; #{account.identifier.to_s}; #{token.to_s}; #{result.to_s}\n")

        logger_infos("user: #{user.code}; account: #{account.id}; couter: #{count}:#{index};")
        sleep 3
      end
    end
  end
end
