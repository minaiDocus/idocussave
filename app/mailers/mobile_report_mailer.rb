class MobileReportMailer < ActionMailer::Base
  def report(data_report)
    @data_report = data_report
    
    mail to: Settings.first.notify_errors_to, subject: "[Erreur mobile] - #{data_report[:title]}"
  end
end
