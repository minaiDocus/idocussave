class Retriever::ResumeBudgeaWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for 'ResumeBudgeaRetriever' do
      Retriever::ResumeBudgea.new().execute
    end
  end
end
