class DataVerificatorMailer < ActionMailer::Base
  def notify(notify_content)
    @notify_content = notify_content

    mail to: Settings.first.notify_errors_to, subject: "[Data Verif] - Scan du #{@notify_content[:date_scan]}"[0..200]
  end
end