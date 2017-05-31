class CreateInvoicePdfWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'CreateInvoicePDF' do
      CreateInvoicePdf.for_all
    end
  end
end
