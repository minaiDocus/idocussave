# -*- encoding : UTF-8 -*-
namespace :fiduceo do
  namespace :operation do
    desc 'Process fiduceo operation'
    task :process => [:environment] do
      user_ids = FiduceoRetriever.active.banks.distinct(:user_id)
      users = User.find user_ids
      users.each do |user|
        fop = FiduceoOperationProcessor.new user if user.is_fiduceo_authorized
        fop.process
      end
    end
  end

  namespace :transaction do
    desc 'Initiate fiduceo transactions'
    task :initiate => [:environment] do
      FiduceoDocumentFetcher.initiate_transactions
      retrievers = FiduceoRetriever.active.banks
      retrievers.each do |retriever|
        if retriever.scheduled? || (retriever.error? && retriever.transactions.last.try(:retryable?))
          FiduceoDocumentFetcher.create_transaction(retriever)
        end
      end
    end
  end

  namespace :provider do
    desc 'Notify processed wishes'
    task :notify_processed_wishes => [:environment] do
      FiduceoProviderWish.deliver_mails
    end
  end
end
