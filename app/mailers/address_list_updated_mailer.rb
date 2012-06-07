class AddressListUpdatedMailer < ActionMailer::Base
  helper :application
  default :from => "do-not-reply@idocus.com"
  
  def notify 
    mail(:to => "lailol@directmada.com", :subject => "Liste d'adresses de retour")
  end
end
