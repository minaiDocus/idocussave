# -*- encoding : UTF-8 -*-
class Account::Charts::OperationsController < Account::AccountController
  before_filter :verify_rights
  before_filter :load_fiduceo_user_id
  before_filter :load_bank_accounts

  def index
    if params[:start_date].present?
      if params[:start_date].is_a? Hash
        @start_date = "#{params[:start_date][:year]}-#{params[:start_date][:month]}-#{params[:start_date][:day]}".to_date rescue Time.now.beginning_of_year.to_date
      else
        @start_date = params[:start_date].to_date rescue Time.now.beginning_of_year.to_date
      end
    else
      @start_date = Time.now.beginning_of_year.to_date
    end

    if params[:end_date].present?
      if params[:end_date].is_a? Hash
        @end_date = "#{params[:end_date][:year]}-#{params[:end_date][:month]}-#{params[:end_date][:day]}".to_date rescue Time.now.end_of_year.to_date
      else
        @end_date = params[:end_date].to_date rescue Time.now.end_of_year.to_date
      end
    else
      @end_date = Time.now.end_of_year.to_date
    end

    respond_to do |format|
      format.html
      format.json do
        fiduceo_operation = FiduceoOperation.new @user.fiduceo_id, account_id: @bank_account_id,
                                                                   from_date: @start_date.strftime("%d/%m/%Y"),
                                                                   to_date: @end_date.strftime("%d/%m/%Y")
        @categories = fiduceo_operation.by_category
        if @categories
          @categories = @categories.select { |e| e.amount <= 0 }
          @categories.each { |e| e.amount = e.amount.abs }
        else
          render json: 'Service temporairement indisponible.', status: 503
        end
      end
    end
  end

private

  def verify_rights
    unless @user.is_fiduceo_authorized
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to root_path
    end
  end
end
