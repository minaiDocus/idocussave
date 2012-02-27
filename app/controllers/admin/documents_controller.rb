class Admin::DocumentsController < Admin::AdminController
  
  before_filter :filtered_user_ids, :only => %w(index)
  
  def index
    @user = User.where(:_id => @filtered_user_ids.first).first
    
    @packs = []
    
    @packs = @user.packs.desc(:created_at) if @user
    
    @packs = @packs.paginate :page => params[:page], :per_page => 50
  end

  def run_background_process
    BackgroundProcess.run
    
    respond_to do |format|
      format.html{ redirect_to admin_documents_path }
      format.json{ render :json => "true".to_json, :status => :ok }
    end
  end
end
