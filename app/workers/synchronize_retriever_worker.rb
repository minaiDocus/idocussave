class SynchronizeRetrieverWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(retriever_id)
    UniqueJobs.for "SynchronizeRetrieverWorker-#{retriever_id}" do
      retriever = Retriever.find retriever_id
      SynchronizeRetriever.new(retriever).execute
    end
  end
end
