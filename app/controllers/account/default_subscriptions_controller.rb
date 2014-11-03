# -*- encoding : UTF-8 -*-
class Account::DefaultSubscriptionsController < Account::OrganizationController
  before_filter :load_subscription, :load_product

  def show
  end

  def edit
    @options = @subscription.product_option_orders.map(&:to_a)
  end

  def update
    @subscription.permit_all_options = true
    if @subscription.update_attributes(scan_subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_default_subscription_path(@organization)
    else
      render action: :'edit'
    end
  end

private

  def scan_subscription_params
    if @user.is_admin
      params.require(:scan_subscription).permit(
        :max_sheets_authorized,
        :unit_price_of_excess_sheet,
        :max_upload_pages_authorized,
        :quantity_of_a_lot_of_upload,
        :price_of_a_lot_of_upload,
        :max_dematbox_scan_pages_authorized,
        :quantity_of_a_lot_of_dematbox_scan,
        :price_of_a_lot_of_dematbox_scan,
        :max_preseizure_pieces_authorized,
        :unit_price_of_excess_preseizure,
        :max_expense_pieces_authorized,
        :unit_price_of_excess_expense,
        :max_paperclips_authorized,
        :unit_price_of_excess_paperclips,
        :max_oversized_authorized,
        :unit_price_of_excess_oversized,
        :payment_type,
        :end_in,
        :period_duration,
        :product)
    else
      params.require(:scan_subscription).permit(:period_duration, :product)
    end
  end

  def load_subscription
    @subscription = @user.find_or_create_scan_subscription
  end

  def load_product
    @products = Product.subscribable
  end
end
