# -*- encoding : UTF-8 -*-
class Account::Documents::TagsController < Account::AccountController
  def update_multiple
    UpdateMultipleTags.execute(@user, params[:tags], params[:document_ids])

    respond_to do |format|
      format.json { render json: {}, status: :ok }
      format.html { redirect_to root_path }
    end
  end
end
