class Account::InvoicesController < Account::AccountController
  def download
    invoice = Invoice.find params[:id]
    filepath = invoice.content.path params[:style]

    owner = invoice.user
    current_user.extend_organization_role
    authorized = false
    authorized = true if current_user == owner || current_user.is_admin || current_user.my_organization == owner.organization || current_user.customers.include?(owner)
    if File.exist?(filepath) && authorized
      filename = File.basename filepath
      type = invoice.content_content_type || 'application/pdf'
      send_file(filepath, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end
end