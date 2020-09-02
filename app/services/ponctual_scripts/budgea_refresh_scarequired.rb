class PonctualScripts::BudgeaRefreshScarequired < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    return false if File.exist? file_path

    retrievers = Retriever.all

    @file = File.open(file_path, 'w+')

    backup_retriever("initial state", "final state", "response")

    count = 0
    retrievers.each do |retriever|
      access_token = retriever.user.try(:budgea_account).try(:access_token)

      next unless retriever.user.still_active? && access_token.present? && retriever.budgea_id.present?

      if count == 5
        sleep(5)
        count = 0
      end

      initial_state = retriever.to_json

      client   = Budgea::Client.new(access_token)
      response = client.send(:resume_connexion, retriever)

      sleep(1)

      count += 1
      backup_retriever(initial_state, retriever.reload.to_json, response.to_json)
    end

    @file.try(:close)
  end

  def backup_retriever(initial, final, response)
    @file.write(initial + ";" + final + ";" + response + "\n")
  end

  def file_path
    File.join(ponctual_dir, 'budgea_connexion', 'refresh_budgea_connection.txt')
  end
end