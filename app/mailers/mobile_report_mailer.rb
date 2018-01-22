class MobileReportMailer < ActionMailer::Base
  def report(subject, data_report)
    @data_report = data_report
    
    mail to: "mina@idocus.com", subject: "[Erreur mobile] - #{subject}"
  end
end
