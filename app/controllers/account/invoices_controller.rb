class Account::InvoicesController < Account::AccountController

  before_filter :load_user

  public

  def download
    invoice = Invoice.find params[:id]
    filepath = invoice.content.path params[:style]
    if File.exist?(filepath) && (invoice.user == @user || invoice.user.try(:prescriber) == @user || @user.try(:is_admin))
      filename = File.basename filepath
      type = invoice.content_file_type || 'application/pdf'
      send_file(filepath, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end
end