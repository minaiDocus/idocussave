class ErrorScriptMailer < ActionMailer::Base
	def error_notification(script)
    @script = script

    mail to: "mina@idocus.com,jean@idocus.com,paul@idocus.com", subject: "[MAIL SCRIPT ERREUR] - #{@script[:name]} - #{@script[:erreur_type]}"[0..200]
	end
end