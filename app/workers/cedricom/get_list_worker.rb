class Cedricom::GetListWorker
  include Sidekiq::Worker
  sidekiq_options queue: :cedricom, retry: false

  def perform
    UniqueJobs.for 'GetList' do
      Organization.cedricom_configured.each do |organization|
        Cedricom::FetchReceptions.new(organization).get_list
      end
    end
  end
end