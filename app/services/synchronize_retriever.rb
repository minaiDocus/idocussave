# -*- encoding : UTF-8 -*-
class SynchronizeRetriever
  def initialize(retriever)
    @retriever = retriever
  end

  def execute
    log "[#{@retriever.user.code}][#{@retriever.budgea_id}][#{@retriever.service_name}] start - #{@retriever.state}"
    start_time = Time.now
    if @retriever.connector.is_budgea_active?
      begin
        $remote_lock.synchronize("create_budgea_account_for_user_id_#{@retriever.user.id}", expiry: 10.seconds) do
          CreateBudgeaAccount.execute(@retriever.user) if @retriever.user.budgea_account.nil?
        end
        SyncBudgeaConnection.execute(@retriever)
      rescue RemoteLock::Error
      end
    end
    log "[#{@retriever.user.code}][#{@retriever.budgea_id}][#{@retriever.service_name}] done - #{@retriever.state} (#{(Time.now - start_time).round(3)} sec)"
  end

private

  def log(message)
    $remote_lock.synchronize 'SynchronizeRetrieverLog', expiry: 1.second do
      logger.info(message)
    end
  end

  def logger
    @@logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_retriever_sync.log")
  end
end
