# -*- encoding : UTF-8 -*-
class Admin::DematboxesController < Admin::AdminController
  before_filter :load_dematbox, except: :index

  def index
    @dematboxes = Dematbox.desc(:created_at)
  end

  def show
  end

  def destroy
    @dematbox.delay(priority: 1).unsubscribe
    flash[:notice] = 'Supprimé avec succès.'
    redirect_to admin_dematboxes_path
  end

  def subscribe
    @dematbox.async_subscribe
    flash[:notice] = 'Configuration en cours...'
    redirect_to admin_dematboxes_path
  end

private

  def load_dematbox
    @dematbox = Dematbox.find params[:id]
  end
end
