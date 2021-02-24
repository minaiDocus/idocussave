class ErrorScriptMailer < ActionMailer::Base
	def error_notification(script, options={})
    return true if Rails.env != 'production'

    @script = script

    if options[:attachements].present?
      options[:attachements].each do |attach|
        attachments[attach[:name]] = attach[:file]
      end
    end

    error_script_mailer = CounterErrorScriptMailer.find_or_create_by_error_type(@script[:error_group])
    error_script_mailer.counter = error_script_mailer.counter.to_i + 1

    if error_script_mailer.counter <=  20 && error_script_mailer.enabled?
      error_script_mailer.save    
      mail to: Settings.first.notify_errors_to, subject: "#{@script[:subject]}"[0..200]
    else
      error_script_mailer.is_enable = false
      error_script_mailer.save
    end
    
	end
end