# -*- encoding : UTF-8 -*-
class Account::CompositionsController < Account::AccountController
  def create
    params[:composition][:user_id] = @user.id
    Composition.create_with_documents params[:composition]

    @url = '/account/compositions/download'

    respond_to do |format|
      format.json do
        render :json => @url.to_json, :status => :ok
      end
    end
  end

  def download
    @composition = @user.composition
    filepath = @composition.try(:path).to_s
    if File.exist?(filepath)
      filename = File.basename(filepath)
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render nothing: true, status: 404
    end
  end

  def reset
    @composition = @user.composition
    @composition.update_attribute(:document_ids, []) if @composition

    respond_to do |format|
      format.json{ render :json => @composition, :status => :ok }
    end
  end
end
