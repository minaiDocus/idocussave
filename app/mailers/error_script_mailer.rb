class ErrorScriptMailer < ActionMailer::Base
	def error_notification(script, options={})
    @script = script

    if options[:attachements].any?
      options[:attachements].each do |attach|
        attachments[attach[:name]] = attach[:file]
      end
    end

    mail to: "mina@idocus.com,jean@idocus.com,paul@idocus.com", subject: "[MAIL SCRIPT ERREUR] - #{@script[:name]} - #{@script[:erreur_type]}"[0..200]
	end
end