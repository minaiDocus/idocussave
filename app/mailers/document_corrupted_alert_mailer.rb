class DocumentCorruptedAlertMailer < ActionMailer::Base
  def notify(email, options={})
    return true if Rails.env != 'production'

    @documents = email[:documents]
    @uploader  = email[:uploader]

    if options[:attachements].present?
      options[:attachements].each do |attach|
        attachments[attach[:name]] = attach[:file]
      end
    end

    dest = @uploader.email.present? ? @uploader.email : 'mina@idocus.com'

    mail(to: dest, cci: Settings.first.notify_errors_to, subject: '[iDocus] Document non traitable')
  end
end