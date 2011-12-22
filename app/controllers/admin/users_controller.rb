class Admin::UsersController < Admin::AdminController

  before_filter :load_user, :only => %w(edit update update_confirm_status update_delivery_status destroy)
  before_filter :format_params, :only => %w(index)

protected

  def load_user
    @user = User.find params[:id]
  end

public

  def index
    @users = User.all
    @users = @users.where(:email => /\w*#{params[:email]}\w*/) if !params[:email].blank?
    @users = @users.where(:first_name => /\w*#{@formatted_first_name}\w*/) if !params[:first_name].blank?
    @users = @users.where(:last_name => /\w*#{@formatted_last_name}\w*/) if !params[:last_name].blank?
    @users = @users.where(:company => /\w*#{params[:company]}\w*/) if !params[:company].blank?
    @users = @users.where(:code => /\w*#{params[:code]}\w*/) if !params[:code].blank?
    
    @users = @users.desc(:created_at).paginate :page => params[:page], :per_page => 50
  end

  def new
    @user = User.new
  end

  def create
    params[:user][:first_name] = params[:user][:first_name].upcase if params[:user][:first_name]
    params[:user][:last_name] = params[:user][:last_name].split.collect{|n| n.capitalize}.join(' ') if params[:user][:last_name]
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
    params[:user][:first_name] = params[:user][:first_name].upcase if params[:user][:first_name]
    params[:user][:last_name] = params[:user][:last_name].capitalize if params[:user][:last_name]
    if @user.update_attributes params[:user]
      params[:user][:clients_email] = [] unless params[:user][:clients_email]
      @user.reporting = Reporting.create unless @user.reporting
      @user.reporting.clients = User.find_by_emails params[:user][:clients_email].split(/\s*,\s*/) - [@user]
      @user.reporting.save
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
  
  def reinitialize_all_delivery_state
    Delivery.all.entries.each do |delivery|
      delivery.state = "nothing"
      delivery.save
    end
    
    redirect_to admin_users_path
  end
end
