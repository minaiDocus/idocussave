# Preview all emails at http://localhost:3000/rails/mailers/mobile_report_mailer
class MobileReportMailerPreview < ActionMailer::Preview
  data_report = {
                    title:      "Erreur App mobile",
                    user_id:    1,
                    user_token: "abcdef",
                    platform:   "android",
                    report:     "no report"
                  }
    MobileReportMailer.report("test", data_report)
end
