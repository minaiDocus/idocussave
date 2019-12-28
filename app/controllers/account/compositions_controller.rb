# frozen_string_literal: true

class Account::CompositionsController < Account::AccountController
  # POST /account/compositions
  def create
    params[:composition][:user_id] = @user.id
    Composition.create_with_documents params[:composition]
    @url = '/account/compositions/download'

    respond_to do |format|
      format.json do
        render json: @url.to_json, status: :ok
      end
    end
  end

  # GET /account/compositions/download
  def download
    @composition = @user.composition
    filepath = @composition.try(:path).to_s

    if File.exist?(filepath)
      filename = File.basename(filepath)
      send_file(filepath, type: 'application/pdf', filename: filename, x_sendfile: true, disposition: 'inline')
    else
      render body: nil, status: 404
    end
  end

  # DELETE /account/compositions/reset
  def reset
    @composition = @user.composition
    @composition&.update_attribute(:document_ids, [])

    respond_to do |format|
      format.json { render json: @composition, status: :ok }
    end
  end
end
