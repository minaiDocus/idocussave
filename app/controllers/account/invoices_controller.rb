class Account::InvoicesController < Account::AccountController
  # GET /account/invoices/:id/download/
  def download
    invoice      = Invoice.find params[:id]
    owner        = invoice.user
    organization = invoice.organization

    @user.extend_organization_role

    authorized = false

    if owner && (@user == owner || @user.my_organization == owner.organization || @user.customers.include?(owner))
      authorized = true
    elsif organization && @user.my_organization == organization
      authorized = true
    elsif @user.is_admin
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
