class PackMailer < ActionMailer::Base
  default :from => "do-not-reply@idocus.com"

  def new_document_available(user, filesname=[])
    @user = user
    @url = "https://www.idocus.com/account/documents"
    @filesname = filesname
    mail(:to => user.email, :subject => "Mise à jour des documents")
  end
end
