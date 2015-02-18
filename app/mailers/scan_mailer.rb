# -*- encoding : UTF-8 -*-
class ScanMailer < ActionMailer::Base
  default from: 'notification@idocus.com'

  def notify_not_delivered(emails, pack_names)
    @pack_names = pack_names
    mail(to: emails, subject: "[iDocus] #{pack_names.size} document(s) scanné(s) mais non livré(s)")
  end
end
