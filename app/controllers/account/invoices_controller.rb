class Account::InvoicesController < Account::AccountController
  # GET /account/invoices/:id/download/
  def download
    invoice      = Invoice.find params[:id]
    owner        = invoice.user
    organization = invoice.organization

    authorized = false

    if owner && (@user == owner || owner.organization.admins.include?(@user) || @user.customers.include?(owner))
      authorized = true
    elsif organization && @user.class == Collaborator && organization.admins.include?(@user.user)
      authorized = true
    elsif @user.admin?
      authorized = true
    end

    if File.exist?(invoice.content.path) && authorized
      filename = File.basename invoice.content.path
      type = invoice.content_content_type || 'application/pdf'
      send_file(invoice.content.path, type: type, filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end
end
