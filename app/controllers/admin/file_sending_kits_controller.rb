class Admin::FileSendingKitsController < Admin::AdminController
  
  before_filter :load_my_file_sending_kit, :only => %w(show edit update destroy generate)
  
protected
  def load_my_file_sending_kit
    @file_sending_kit = FileSendingKit.find params[:id]
  end
  
public
  def index
    @file_sending_kits = FileSendingKit.all.by_position.paginate :page => params[:page], :per_page => 50
  end
  
  def show
  end
  
  def new
    @file_sending_kit = FileSendingKit.new
  end
  
  def create
    @file_sending_kit = FileSendingKit.new params[:file_sending_kit]
    if @file_sending_kit.save
      flash[:notice] = "Crée avec succès."
      redirect_to admin_file_sending_kits_path
    else
      flash[:error] = "Erreur lors de la création."
      render :action => "new"
    end
  end
  
  def edit
  end
  
  def update
    if @file_sending_kit.update_attributes params[:file_sending_kit]
      flash[:notice] = "Modifiée avec succès."
      redirect_to admin_file_sending_kits_path
    else
      flash[:error] = "Erreur lors de la création."
      render :action => "new"
    end
  end
  
  def destroy
    @file_sending_kit.destroy
    flash[:notice] = "Supprimé avec succès."
    redirect_to admin_file_sending_kits_path
  end
  
  def generate
    clients_data = []
    @file_sending_kit.user.clients.each do |client|
      value = params[:users]["#{client.id}"][:is_checked] rescue nil
      if value == "true"
        clients_data << { :user => client, :start_month => params[:users]["#{client.id}"][:start_month].to_i, :offset_month => params[:users]["#{client.id}"][:offset_month].to_i }
      end
    end
    
    FileSendingKitGenerator::generate clients_data, @file_sending_kit
    flash[:notice] = "Généré avec succès."
    @is_generated = true
    render :action => "show"
  end

end