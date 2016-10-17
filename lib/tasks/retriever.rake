# -*- encoding : UTF-8 -*-
namespace :retriever do
  desc 'Notify password renewal'
  task :notify_password_renewal => [:environment] do
    puts "[#{Time.now}] retriever:notify_password_renewal - START"
    user_ids = Retriever.new_password_needed
    groups = retrievers.group_by(&:user)
    groups.each do |user, retrievers|
      RetrieverMailer.notify_password_renewal(user).deliver
      retrievers.each do |retriever|
        retriever.update(is_new_password_needed: false)
      end
    end
    puts "[#{Time.now}] retriever:notify_password_renewal - END"
  end

  desc 'Notify insane retrievers'
  task :notify_insane_retrievers => [:environment] do
    puts "[#{Time.now}] retriever:notify_insane_retriever - START"
    InsaneRetrieverFinder.execute
    puts "[#{Time.now}] retriever:notify_insane_retriever - END"
  end

  namespace :provider do
    desc 'Notify processed wishes'
    task :notify_processed_wishes => [:environment] do
      puts "[#{Time.now}] retriever:provider:notify_processed_wishes - START"
      RetrieverProviderWish.deliver_mails
      puts "[#{Time.now}] retriever:provider:notify_processed_wishes - END"
    end
  end
end
