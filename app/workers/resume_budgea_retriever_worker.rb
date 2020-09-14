class ResumeBudgeaRetrieverWorker
  include Sidekiq::Worker

  def perform
    UniqueJobs.for 'ResumeBudgeaRetriever' do
      ResumeBudgeaRetriever.new().execute
    end
  end
end
