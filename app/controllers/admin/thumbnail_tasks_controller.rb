class Admin::ThumbnailTasksController < Admin::AdminController

protected

  def get_status
    @is_reprocess_styles_running = true
    if `lib/daemons/reprocess_styles_ctl status`.match(/no instances running/)
      @is_reprocess_styles_running = false
    end
  end

public

  def start
    `lib/daemons/reprocess_styles_ctl start`
    
    respond_to do |format|
      format.html{}
      format.json{ render :json => "true".to_json, :status => :ok }
    end
  end
  
  def stop
    `lib/daemons/reprocess_styles_ctl stop`
    
    respond_to do |format|
      format.html{}
      format.json{ render :json => "true".to_json, :status => :ok }
    end
  end
  
  def status
    get_status
    
    respond_to do |format|
      format.html{}
      format.json{ render :json => @is_reprocess_styles_running.to_json, :status => :ok }
    end
  end
  
  def remain
    @remain = Document.count(:conditions => { :dirty => true })
    
    respond_to do |format|
      format.html{}
      format.json{ render :json => @remain.to_json, :status => :ok }
    end
  end
end
