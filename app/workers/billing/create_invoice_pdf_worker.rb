class Billing::CreateInvoicePdfWorker
  include Sidekiq::Worker
  sidekiq_options queue: :high, retry: false

  def perform
    UniqueJobs.for 'CreateInvoicePDF' do
      Billing::CreateInvoicePdf.for_all
    end
  end
end
