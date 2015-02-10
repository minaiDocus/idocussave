# -*- encoding : UTF-8 -*-
namespace :fiduceo do
  namespace :transaction do
    desc 'Initiate fiduceo transactions'
    task :initiate => [:environment] do
      weekday = Time.now.strftime('%a').downcase
      retrievers = FiduceoRetriever.active.auto.where(frequency: /(day|#{weekday})/, :state.in => %w(ready scheduled error))
      FiduceoDocumentFetcher.initiate_transactions(retrievers)
    end
  end

  namespace :provider do
    desc 'Notify processed wishes'
    task :notify_processed_wishes => [:environment] do
      FiduceoProviderWish.deliver_mails
    end
  end
end
