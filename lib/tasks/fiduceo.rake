# -*- encoding : UTF-8 -*-
namespace :fiduceo do
  desc 'Notify password renewal'
  task :notify_password_renewal => [:environment] do
    retrievers = FiduceoRetriever.active.auto.password_renewal_not_notified.where(state: 'error', service_name: /BNP/i).select do |retriever|
      transaction = retriever.transactions.desc(:created_at).first
      transaction.status == 'CHECK_ACCOUNT' && transaction.events['lastUserInfo'] == 'Erreur : Vous devez vous connecter sur le site de la banque pour changer votre mot de passe'
    end
    groups = retrievers.group_by(&:user)
    groups.each do |user, retrievers|
      FiduceoRetrieverMailer.notify_password_renewal(user).deliver
      retrievers.each do |retriever|
        retriever.update_attribute(:is_password_renewal_notified, true)
      end
    end
  end

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
