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

  desc 'Clean oldest retrieved data'
  task :clean_retrieved_data => [:environment] do
    puts "[#{Time.now}] retriever:clean_retrieved_data - START"
    RetrievedData.remove_oldest
    puts "[#{Time.now}] retriever:clean_retrieved_data - END"
  end

  namespace :provider do
    desc 'Notify processed requests'
    task :notify_processed_requests => [:environment] do
      puts "[#{Time.now}] retriever:provider:notify_processed_requests - START"
      NewProviderRequest.deliver_mails
      puts "[#{Time.now}] retriever:provider:notify_processed_requests - END"
    end
  end
end
