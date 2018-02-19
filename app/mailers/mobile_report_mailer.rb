class MobileReportMailer < ActionMailer::Base
  def report(data_report)
    @data_report = data_report
    
    mail to: "mina@idocus.com", subject: "[Erreur mobile] - #{data_report[:title]}"
  end
end
