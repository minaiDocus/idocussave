class SynchronizeRetrieverWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(retriever_id)
    UniqueJobs.for "SynchronizeRetrieverWorker-#{retriever_id}" do
      retriever = Retriever.find retriever_id
      SynchronizeRetriever.new(retriever).execute if retriever.not_processed?
    end
  end
end
