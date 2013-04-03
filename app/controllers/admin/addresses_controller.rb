class Admin::AddressesController < Admin::AdminController
  layout :nil_layout

  before_filter :load_user

  protected

  def load_user
    @user = User.find params[:user_id]
  end

  public

  def index
    @billing_address = @user.addresses.for_billing.first
    @shipping_address = @user.addresses.for_shipping.first
  end

  def edit_multiple
  end

  def update_multiple
    respond_to do |format|
      if @user.update_attributes(user_params)
        format.json{ render json: {}, status: :ok }
        format.html{ redirect_to admin_user_path(@user) }
      else
        format.json{ render json: @user.errors.to_json, status: :unprocessable_entity }
        format.html{ render action: 'edit_multiple' }
      end
    end
  end

private

  def user_params
    params.require(:user).permit!
  end
end
