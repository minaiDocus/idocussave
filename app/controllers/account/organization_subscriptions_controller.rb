# -*- encoding : UTF-8 -*-
class Account::OrganizationSubscriptionsController < Account::OrganizationController
  before_filter :verify_rights

  def edit
    @subscription = @organization.find_or_create_subscription
    @products     = Product.subscribable
    @options      = @subscription.product_option_orders.map(&:to_a)
  end

  def update
    @subscription = @organization.find_or_create_subscription
    if @subscription.update_attributes(scan_subscription_params)
      flash[:success] = 'Modifié avec succès.'
      redirect_to account_organization_path(@organization, tab: 'subscription')
    else
      render 'edit'
    end
  end

private

  def verify_rights
    unless @user.is_admin
      flash[:error] = t('authorization.unessessary_rights')
      redirect_to account_organization_path(@organization)
    end
  end

  def scan_subscription_params
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
      :period_duration,
      :product,
      :is_to_spreading)
  end
end
