# -*- encoding : UTF-8 -*-
class DataVerificator::ErrorScriptMailerInfo < DataVerificator::DataVerificator
  def execute
    error_script_mailers = CounterErrorScriptMailer.where("updated_at >= ? AND updated_at <= ?", 1.days.ago, Time.now)

    messages = []

    error_script_mailers.each do |error_script_mailer|
      messages << "error_type: #{error_script_mailer.error_type}, counter: #{error_script_mailer.counter}, is_enable: #{error_script_mailer.enabled?}"

      error_script_mailer.is_enable = true if error_script_mailer.counter <= 20
      error_script_mailer.counter   = 0
      error_script_mailer.save
    end

    {
      title: "ErrorScriptMailerInfo - #{error_script_mailers.size} error(s) script mailer found",
      message: messages.join('; ')
    }
  end
end