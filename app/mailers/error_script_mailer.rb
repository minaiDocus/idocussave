class ErrorScriptMailer < ActionMailer::Base
	def error_notification(script, options={})
    @script = script

    if options[:attachements].present?
      options[:attachements].each do |attach|
        attachments[attach[:name]] = attach[:file]
      end
    end

    mail to: Settings.first.notify_errors_to, subject: "[MAIL SCRIPT ERREUR] - #{@script[:name]} - #{@script[:erreur_type]}"[0..200]
	end
end