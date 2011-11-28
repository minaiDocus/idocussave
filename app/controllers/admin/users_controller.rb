class Admin::UsersController < Admin::AdminController

  before_filter :load_user, :only => %w(edit update update_confirm_status update_delivery_status destroy)

protected

  def load_user
    @user = User.find params[:id]
  end

public

  def index
    @users = User.desc(:created_at).paginate :page => params[:page]
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new params[:user]
    @user.skip_confirmation!
    if @user.save
      redirect_to admin_users_path
    else
      render :action => "new"
    end
  end

  def edit
  end
  
  def update
    if @user.update_attributes params[:user]
      debugger
      params[:user][:clients_email] = [] unless params[:user][:clients_email]
      @user.reporting = Reporting.create unless @user.reporting
      @user.reporting.clients = User.find_by_emails params[:user][:clients_email].split(/\s*,\s*/)
      @user.save
      redirect_to admin_users_path
    else
      render :action => "edit"
    end
  end
  
  def update_confirm_status
    @user.confirm!
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to admin_users_path }
    end
  end
  
  def update_delivery_status
    debugger
    unless @user.delivery
      @user.delivery = Delivery.create
      @user.save
    end
    @user.delivery.state = params[:value]
    @user.delivery.save!
    
    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
      format.html{ redirect_to admin_users_path }
    end
  end

  def destroy
    SharedDocument.where(:owner => @user.id).delete rescue nil
    SharedDocument.where(:observer => @user.id).delete rescue nil
    @user.orders.each do |order|
      order.documents.each do |document|
        document.document_tags.destroy_all rescue nil
      end
      order.documents.destroy_all
      order.order_transactions.destroy_all
      order.paypal_transactions.destroy_all
      order.invoice.destroy rescue nil
      order.destroy
    end
    if @user.composition
      system("cd #{Rails.root}/public/system/compositions/rm -r #{@user.composition.id}");
      @user.composition.destroy
    end
    @user.destroy
    redirect_to admin_users_path
  end
end
