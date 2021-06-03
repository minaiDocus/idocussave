class DocumentCorruptedAlertMailer < ActionMailer::Base
	def notify(mail, options={})
    # return true if Rails.env != 'production'

    @documents = mail[:documents]
    @uploader  = mail[:uploader]

    if options[:attachements].present?
      options[:attachements].each do |attach|
        attachments[attach[:name]] = attach[:file]
      end
    end

    # mail(to: @uploader.email, cc: @uploader.prescribers.map{ |colab| colab.email }, subject: '[iDocus] Document non traitable')
    mail(to: Settings.first.notify_errors_to, subject: '[iDocus] Document non traitable')
	end
end