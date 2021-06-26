class Cedricom::GetListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'GetList' do
      Cedricom::FetchReceptions.new.get_list
    end
  end
end