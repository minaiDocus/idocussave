class PonctualScripts::BudgeaRefreshScarequired < PonctualScripts::PonctualScript
  def self.execute
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    get_budgea_ids

    retrievers = Retriever.all

    @file = File.open(file_path, 'w+')
    @error = File.open(error_file, 'w+')

    backup_retriever("initial state", "final state", "response")

    count = 0

    retrievers.each do |retriever|
      access_token = retriever.user.try(:budgea_account).try(:access_token)

      next if retriever.id < @retriever_ids.last.to_i
      next unless retriever.user.still_active? && access_token.present? && retriever.budgea_id.present?

      if count == 5
        sleep(7)
        count = 0
      end

      initial_state = retriever.to_json

      client   = Budgea::Client.new(access_token)
      begin
        response = client.resume_connexion(retriever)

        p "=====#{retriever.id}=======>>\n#{response.to_json}\n\n"
        sleep(1)

        backup_retriever(initial_state, retriever.reload.to_json, response.to_json)
      rescue => e
        p "------------ #{retriever.id.to_s} => #{e.to_s} -------"
        @error.write(retriever.id.to_s + ";" + e.to_s.gsub(";", ",") +  "\n")
      end

      count += 1
    end

    @file.try(:close)
  end

  def backup_retriever(initial, final, response)
    @file.write(initial + ";" + final + ";" + response + "\n")
  end

  def copy_backup
    return false unless File.exist?(file_path)
    FileUtils.cp file_path, file_copy
    true
  end

  def file_path
    File.join(ponctual_dir, 'budgea_connexion', 'refresh_budgea_connection.txt')
  end

  def file_copy
    File.join(ponctual_dir, 'budgea_connexion', 'refresh_budgea_connection_2.txt')
  end

  def error_file
    File.join(ponctual_dir, 'budgea_connexion', "refresh_budgea_connection_error_#{Time.now.strftime("%Y%m%d%H%i%s")}.txt")
  end

  def get_budgea_ids
    @retriever_ids = []
    return false unless copy_backup

    File.read(file_copy).each_line do |line|
      explode = line.split(';')
      begin
        @retriever_ids << JSON.parse(explode[0]).try(:[], 'id').presence || 0
      rescue
      end
    end
  end
end