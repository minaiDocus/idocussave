class RetrieveFiduceoOperationsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :retrieve_fiduceo_operations, retry: :false, unique: :until_and_while_executing

  def perform
    BankAccount.all.each do |bank_account|
      if bank_account.retriever && bank_account.retriever.transaction_status == 'COMPLETED'
        OperationService.delay(queue: :retrieve_fiduceo_operations).fetch(bank_account.id)
      end
    end
  end
end
