module Admin::BaseAdminMixin
  protected
  
  def load_model
    @obj = model_class.find(params[:id])
    instance_variable_set("@#{model_class.name.underscore}", @obj)
  end

  def pre_create_hook
  end

  def post_create_hook
  end

  def pre_update_hook
  end

  def post_update_hook
  end

  def pre_index_hook
  end

  def post_index_hook
  end

  public

  def index
    pre_index_hook

    @search = model_class.all
    @search.asc(:position) if model_class.fields.has_key?("position")
    instance_variable_set("@#{model_class.name.underscore.pluralize}", @search.paginate(:page => params[:page], :per_page => 30))

    post_index_hook
  end

  def show
  end

  def new
    instance_variable_set("@#{model_class.name.underscore}",model_class.new)
  end


  def create
    pre_create_hook

    @obj = model_class.new(params[model_class.name.underscore.intern])
    instance_variable_set("@#{model_class.name.underscore}", @obj)
    if @obj.save
      flash[:notice] = "Crée avec succès."
      redirect_to :action => :index
    else
      flash[:error] = "Erreur lors de la création."
      render :action => :new
    end

    post_create_hook
  end

  def edit
  end


  def update

    pre_update_hook

    if @obj.update_attributes(params[model_class.name.underscore.intern])
      flash[:notice] = "Sauvegardé avec succès."
      redirect_to :action => "index"
    else
      flash[:error] = "Erreur lors de la modification."
      render :action => "edit"
    end

    post_update_hook
  end
  
  def destroy
    if @obj.destroy
      flash[:notice] = "Supprimé avec succès !"
    else
      flash[:error] = "Suppression impossible."
    end
    redirect_to :action => "index"
  end
  
end
