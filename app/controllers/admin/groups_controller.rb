class Admin::GroupsController < Admin::AdminController

  before_filter :load_group, :only => %w(edit update destroy)

protected

  def load_group
    @group = Group.find_by_slug params[:id]
  end

public

  def index
    @groups = Group.by_position.all
  end

  def new
    @group = Group.new
  end

  def create
    @group = Group.new params[:group]
    if @group.save
      redirect_to admin_products_path
    else
      render :action => "new"
    end
  end

  def edit
  end

  def update
    if @group.update_attributes params[:group]
      redirect_to admin_products_path
    else
      render :action => "edit"
    end
  end

  def destroy
    @group.destroy
    redirect_to admin_products_path
  end
end
