# -*- encoding : UTF-8 -*-
class SynchronizeRetriever
  def initialize(retriever)
    @retriever = retriever
  end

  def execute
    logger.info "[#{@retriever.user.code}][Retriever:#{@retriever.budgea_id}][#{@retriever.service_name}] start - #{@retriever.state}"
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
    logger.info "[#{@retriever.user.code}][Retriever:#{@retriever.budgea_id}][#{@retriever.service_name}] done - #{@retriever.state} (#{(Time.now - start_time).round(3)} sec)"
  end

private

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_processing.log")
  end
end
