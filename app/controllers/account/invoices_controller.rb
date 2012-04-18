class Account::InvoicesController < Account::AccountController

public
  def index
  end
  
  def show
    @invoice = current_user.invoices.find_by_slug params[:id]
  end

end
