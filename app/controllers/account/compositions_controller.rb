# -*- encoding : UTF-8 -*-
class Account::CompositionsController < Account::AccountController

  before_filter :load_composition, :only => %w(destroy show reorder delete_document)

protected

  def load_composition
    @composition = current_user.composition
  end

public

  def create
    params[:composition][:user_id] = current_user.id
    Composition.create_with_documents params[:composition]
    composition = Composition.where(:user_id => current_user.id).first
    
    @url = "/system/compositions/#{composition.id}/#{composition.name}.pdf"
    
    respond_to do |format|
      format.json do
        render :json => @url.to_json, :status => :ok
      end
    end
  end

  def destroy
    @composition.destroy
    
    respond_to do |format|
      format.json{ render :json => @composition, :status => :ok }
    end
  end

  def reorder
    @composition.reorder params[:document_ids] if params[:document_ids].all?{|did| Document.find(did).user == current_user }

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end

  def delete_document
    @composition.delete_document params[:document_id]

    respond_to do |format|
      format.json{ render :json => {}, :status => :ok }
    end
  end
end
