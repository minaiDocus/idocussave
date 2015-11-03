# -*- encoding : UTF-8 -*-
namespace :fiduceo do
  desc 'Notify password renewal'
  task :notify_password_renewal => [:environment] do
    puts "[#{Time.now}] fiduceo:notify_password_renewal - START"
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
    puts "[#{Time.now}] fiduceo:notify_password_renewal - END"
  end

  desc 'Notify insane retrievers'
  task :notify_insane_retrievers => [:environment] do
    puts "[#{Time.now}] fiduceo:notify_insane_retriever - START"
    InsaneRetrieverFinder.execute
    puts "[#{Time.now}] fiduceo:notify_insane_retriever - END"
  end

  namespace :transaction do
    desc 'Initiate fiduceo transactions'
    task :initiate => [:environment] do
      puts "[#{Time.now}] fiduceo:transaction:initiate - START"
      weekday = Time.now.strftime('%a').downcase
      retrievers = FiduceoRetriever.active.auto.where(frequency: /(day|#{weekday})/, :state.in => %w(ready scheduled error))
      FiduceoDocumentFetcher.initiate_transactions(retrievers)
      puts "[#{Time.now}] fiduceo:transaction:initiate - END"
    end
  end

  namespace :provider do
    desc 'Notify processed wishes'
    task :notify_processed_wishes => [:environment] do
      puts "[#{Time.now}] fiduceo:provider:notify_processed_wishes - START"
      FiduceoProviderWish.deliver_mails
      puts "[#{Time.now}] fiduceo:provider:notify_processed_wishes - END"
    end
  end
end
