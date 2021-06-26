class Cedricom::FetchReceptionstWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'FetchReceptions' do
      Cedricom::FetchReceptions.fetch_missing_contents
    end
  end
end