class Admin::UsersController < Admin::AdminController

  before_filter :load_user, :only => %w(show edit update update_confirm_status update_delivery_status destroy)
  before_filter :filtered_user_ids, :only => %w(index)

protected

  def load_user
    @user = User.find params[:id]
  end

public

  def index
    @users = User.all
  
    @users = @users.any_in(:_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    
    @users = @users.desc(:created_at).paginate :page => params[:page], :per_page => 50
  end
  
  def show
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
      flash[:notice] = "Crée avec succès."
      redirect_to admin_users_path
    else
      flash[:error] = "Erreur lors de la création."
      render :action => "new"
    end
  end

  def edit
  end
  
  def update
    if @user.update_attributes params[:user]
      flash[:notice] = "Modifiée avec succès."
      redirect_to admin_users_path
    else
      flash[:error] = "Erreur lors de la modification."
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
    delivery = nil
    
    reporting = @user.find_or_create_reporting
    if params[:current_month]
      if params[:current_month] == "false"
        delivery = reporting.monthly.previous.delivery rescue nil
      else
        delivery = reporting.find_or_create_current_monthly.delivery
      end
    else
      delivery = reporting.find_or_create_current_monthly.delivery
    end
    
    if delivery && delivery.update_attributes(:state => params[:value])
      respond_to do |format|
        format.json{ render :json => {}, :status => :ok }
        format.html{ redirect_to admin_users_path }
      end
    else
      respond_to do |format|
        format.json{ render :json => {}, :status => :error }
        format.html{ render :action => "edit" }
      end
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

  def search
    @tags = []
    if !params[:q].blank?
      users = User.where(:email => /.*#{params[:q]}.*/)
      
      if params[:reporting].blank?
        users.each do |user|
          @tags << {"id" => "#{user.id}", "name" => "#{user.email}"}
        end
      else
        users = users.prescribers
        users.entries.each do |user|
          user.create_reporting if user.reporting.nil?
        end
        debugger
        users.entries.each do |user|
          @tags << {"id" => "#{user.id}", "name" => "#{user.own_reporting.id}"}
        end
      end
    end
    respond_to do |format|
      format.json{ render :json => @tags.to_json, :callback => params[:callback], :status => :ok }
    end
  end
end
