class RetrieveFiduceoOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrieve_fiduceo_operations, retry: :false, unique: :until_and_while_executing

  def perform
    BankAccount.all.each do |bank_account|
      OperationService.fetch(bank_account) if bank_account.retriever.transaction_status == 'COMPLETED'
      puts '.'
    end
  end
end
