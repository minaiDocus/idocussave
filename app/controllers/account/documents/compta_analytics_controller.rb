# frozen_string_literal: true

class Account::Documents::ComptaAnalyticsController < Account::AccountController
  def update_multiple
    pieces = Pack::Piece.where("id IN (#{params[:document_ids].presence || 0}) AND pre_assignment_state != 'ready'")

    messages = PiecesAnalyticReferences.new(pieces, params[:analytic]).update_analytics

    respond_to do |format|
      format.json { render json: { error_message: messages[:error_message], sending_message: messages[:sending_message] }, status: :ok }
      format.html { redirect_to root_path }
    end
  end
end
