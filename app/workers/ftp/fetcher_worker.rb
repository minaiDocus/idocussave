class Ftp::FetcherWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform
    if FTPDeliveryConfiguration::IS_ENABLED
      UniqueJobs.for 'FtpFetcher' do
        Ftp::Fetcher.fetch(FTPDeliveryConfiguration::FTP_SERVER,
                         FTPDeliveryConfiguration::FTP_USERNAME,
                         FTPDeliveryConfiguration::FTP_PASSWORD,
                         FTPDeliveryConfiguration::FTP_PATH,
                         FTPDeliveryConfiguration::FTP_PROVIDER)
      end
    end
  end
end
