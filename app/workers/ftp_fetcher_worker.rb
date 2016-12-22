class FtpFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: :false, unique: :until_and_while_executing


  def perform
    FtpFetcher.fetch(PPPFtpConfiguration::FTP_SERVER,
                     PPPFtpConfiguration::FTP_USERNAME,
                     PPPFtpConfiguration::FTP_PASSWORD,
                     PPPFtpConfiguration::FTP_PATH,
                     PPPFtpConfiguration::FTP_PROVIDER)
  end
end
