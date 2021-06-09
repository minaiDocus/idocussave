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

    # mail(to: @uploader.try(:email), subject: '[iDocus] Documents non traitable') if @uploader.try(:email)
    mail(to: Settings.first.notify_errors_to, subject: '[iDocus] Document non traitable')
  end
end