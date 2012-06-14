class AddressListUpdatedMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify(email)
    mail(:to => email, :subject => "Liste d'adresses de retour")
  end
end
