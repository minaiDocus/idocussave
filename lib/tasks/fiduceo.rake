# -*- encoding : UTF-8 -*-
namespace :fiduceo do
  namespace :operation do
    desc 'Process fiduceo operation'
    task :process => [:environment] do
      user_ids = FiduceoRetriever.active.banks.distinct(:user_id)
      users = User.find user_ids
      users.each do |user|
        FiduceoOperationProcessor.new user if user.is_fiduceo_authorized
      end
    end
  end

  namespace :transaction do
    desc 'Initiate fiduceo transactions'
    task :initiate => [:environment] do
      FiduceoDocumentFetcher.initiate_transactions
    end
  end
end
