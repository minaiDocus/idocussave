# -*- encoding : UTF-8 -*-
class Admin::BackupsController < Admin::AdminController
	
  before_filter :load_backup, :only => %w(edit update)
  before_filter :filtered_user_ids, :only => %w(index)
  
protected
  def load_backup
    @backup = Backup.find params[:id]
  end
  
public
	def index
    @backups = Backup.all
    
    @backups = @backups.any_in(:user_id => @filtered_user_ids) if !@filtered_user_ids.empty?
    
    @backups = @backups.desc(:created_at).paginate :page => params[:page], :per_page => 50
	end
  
  def edit
  end
  
  def update
    if @backup.set_state(params[:backup][:state]) == true
      flash[:notice] = "Modifié acec succès."
    else
      flash[:error] = "Impossible de modifier."
    end
    
    redirect_to admin_backups_path
  end
  
  def service
    if params[:function_name]
      @result = ""
      method = NeobeApi::METHOD_LIST.select{ |ml| ml.match(/#{params[:function_name]}.*/) }.first
      args_s = method.sub(/\)/,'').split(/\(/)[1]
      if args_s
        args = args_s.split(/\s*,\s*/)
        if args.length == 1
          @result = NeobeApi.send params[:function_name], params[:account_number]
        elsif args.length == 2
          @result = NeobeApi.send(params[:function_name], params[:account_number], params[args[1]])[:value]
        elsif args.length == 7
          @result = NeobeApi.send(params[:function_name], params[:space], params[:recipient], params[:password], params[:expiration], params[:unlocker], params[:local], params[:dd])[:value]
        else
          falsh[:error] = "Le nombre de paramétre est incorrecte"
        end
      else
        @result = NeobeApi.send params[:function_name]
      end
    else
      @result = ""
    end
  end
  
end
