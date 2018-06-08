# -*- encoding : UTF-8 -*-
# Updates period with last subscription informations
class UpdatePeriod
  def initialize(period)
    @period          = period
    @subscription    = period.subscription
  end


  def execute
    @period.with_lock(timeout: 3, retries: 30, retry_sleep: 0.1) do
      @subscription.reload

      @period.duration = @subscription.period_duration

      copyable_keys.each do |key|
        @period[key] = @subscription[key]
      end

      @period.product_option_orders.destroy_all
      @period.product_option_orders = options

      UpdatePeriodPriceService.new(@period).execute if @period.save # updates period pricing if sucess
    end
  end

  private


  def copyable_keys
    [
      :max_sheets_authorized,
      :max_upload_pages_authorized,
      :max_preseizure_pieces_authorized,
      :max_expense_pieces_authorized,
      :max_paperclips_authorized,
      :max_oversized_authorized,
      :max_dematbox_scan_pages_authorized,
      :unit_price_of_excess_sheet,
      :unit_price_of_excess_upload,
      :unit_price_of_excess_preseizure,
      :unit_price_of_excess_expense,
      :unit_price_of_excess_paperclips,
      :unit_price_of_excess_oversized,
      :unit_price_of_excess_dematbox_scan
    ]
  end


  def options
    if @subscription.organization
      _options = [extra_options, discount_options]
    else
      _options = [base_options, journals_option, order_options, extra_options]
    end

    _options.flatten.compact.each_with_index do |option, index|
      option.group_position = option.position = index + 1
    end
  end


  def base_options
    if @subscription.is_annual_package_active
      annual_subscription_option
    else
      type = @subscription.period_duration == 1 ? 0 : 1

      selected_options = []

      is_base_package_priced = false

      if @subscription.is_basic_package_active
        is_base_package_priced = true

        price = package_options_price([:subscription, :pre_assignment], type)

        option = ProductOptionOrder.new

        option.title    = 'Téléchargement + Pré-saisie comptable'
        option.name     = 'basic_package_subscription'
        option.duration = 0
        option.quantity = 1
        option.group_title = "iDo'Basique"
        option.is_to_be_disabled = @subscription.is_basic_package_to_be_disabled
        option.price_in_cents_wo_vat = price

        selected_options << option
      end

      if @subscription.is_micro_package_active
        is_base_package_priced = true

        price = package_options_price([:subscription], type)

        option = ProductOptionOrder.new

        option.title    = 'Téléchargement + Pré-saisie comptable + Engagement 12 mois'
        option.name     = 'micro_package_subscription'
        option.duration = 0
        option.quantity = 1
        option.group_title = "iDo'Micro"
        option.is_to_be_disabled     = @subscription.is_micro_package_to_be_disabled
        option.price_in_cents_wo_vat = price

        selected_options << option
      end

      if @subscription.is_mini_package_active
        is_base_package_priced = true

        price = package_options_price([:subscription, :pre_assignment], type)

        option = ProductOptionOrder.new

        option.title    = 'Téléchargement + Pré-saisie comptable + Engagement 12 mois'
        option.name     = 'mini_package_subscription'
        option.duration = 0
        option.quantity = 1
        option.group_title = "iDo'Mini"
        option.is_to_be_disabled     = @subscription.is_micro_package_to_be_disabled
        option.price_in_cents_wo_vat = price

        selected_options << option
      end

      if @subscription.is_mail_package_active
        if is_base_package_priced
          price = package_options_price([:return_paper], type)
        else
          is_base_package_priced = true

          price = package_options_price([:subscription, :pre_assignment, :return_paper], type)
        end

        option = ProductOptionOrder.new

        option.title    = 'Téléchargement + Envoi par courrier A/R + Pré-saisie comptable'
        option.name     = 'mail_package_subscription'
        option.duration = 0
        option.quantity = 1
        option.group_title = "iDo'Courrier"
        option.is_to_be_disabled     = @subscription.is_mail_package_to_be_disabled
        option.price_in_cents_wo_vat = price

        selected_options << option

        if @subscription.is_stamp_active
          option = ProductOptionOrder.new

          option.title    = 'Tamponnage du papier en sortie de numérisation'
          option.name = 'mail_package-stamp'
          option.duration = 0
          option.quantity = 1
          option.group_title = "iDo'Courrier - Option"
          option.is_to_be_disabled     = @subscription.is_stamp_to_be_disabled
          option.price_in_cents_wo_vat = package_options_price([:stamp], type)

          selected_options << option
        end
      end

      if @subscription.is_scan_box_package_active
        if is_base_package_priced
          price = 0.0
        else
          price = package_options_price([:subscription, :pre_assignment], type)
        end

        option = ProductOptionOrder.new

        option.title   = "Téléchargement + Scan par iDocus'Box + Pré-saisie comptable"
        option.name = 'dematbox_package_subscription'
        option.duration = 0
        option.quantity = 1
        option.group_title = "iDo'Box"
        option.is_to_be_disabled     = @subscription.is_scan_box_package_to_be_disabled
        option.price_in_cents_wo_vat = price

        selected_options << option
      end

      if @subscription.is_retriever_package_active
        option = ProductOptionOrder.new

        option.title    = 'Récupération banque + Factures sur Internet'
        option.name = 'retriever_package_subscription'
        option.duration = 0
        option.quantity = 1
        option.group_title = "iDo'FacBanque"
        option.is_to_be_disabled     = @subscription.is_retriever_package_to_be_disabled
        option.price_in_cents_wo_vat = package_options_price([@subscription.retriever_price_option], type)

        selected_options << option
      end

      if (@subscription.is_basic_package_active || @subscription.is_mini_package_active || @subscription.is_mail_package_active || @subscription.is_scan_box_package_active) && !@subscription.is_pre_assignment_active
        option = ProductOptionOrder.new

        option.title    = 'Suppression pré-saisie comptable des factures'
        option.name = 'all_package-disable_pre_assignment'
        option.duration = 0
        option.quantity = 1
        option.group_title = 'Tous forfaits'
        option.price_in_cents_wo_vat = -package_options_price([:pre_assignment], type)

        selected_options << option
      end

      selected_options
    end
  end


  def annual_subscription_option
    option = ProductOptionOrder.new

    option.title       = "Envoi courrier + Téléchargement + iDo'FacBanque + Pré-saisie comptable"
    option.name        = 'annual_package_subscription'
    option.duration    = 0
    option.quantity    = 1
    option.group_title = 'Pack Annuel'
    option.price_in_cents_wo_vat = 19_900.0

    option
  end


  def journals_option
    additionnal_journals = @subscription.number_of_journals - 5

    if additionnal_journals > 0
      option = ProductOptionOrder.new

      option.name        = 'excess_journals'
      option.group_title = 'Tous forfaits'

      if additionnal_journals == 1
        option.title = "#{additionnal_journals} journal comptable supplémentaire"
      else
        option.title = "#{additionnal_journals} journaux comptables supplémentaires"
      end

      option.duration = 0
      option.quantity = additionnal_journals
      option.price_in_cents_wo_vat = additionnal_journals * 100.0

      option
    end
  end


  def extra_options
    @subscription.options.by_position.map do |extra_option|
      option = ProductOptionOrder.new

      option.title       = extra_option.name
      option.name        = 'extra_option'
      option.duration    = extra_option.period_duration
      option.group_title = 'Autres'
      option.is_an_extra = true
      option.price_in_cents_wo_vat = extra_option.price_in_cents_wo_vat

      option
    end
  end

  def discount_options
    discount = DiscountBillingService.new(@subscription.organization)

    option = ProductOptionOrder.new

    option.title       = discount.title
    option.name        = 'discount_option'
    option.duration    = 1
    option.group_title = 'Autres'
    option.is_an_extra = true
    option.price_in_cents_wo_vat = discount.total_amount_in_cents

    option
  end

  def order_options
    @period.orders.order(created_at: :asc).map do |order|
      option      = ProductOptionOrder.new
      option.name = 'extra_option'

      if order.dematbox?
        option.title       = "Commande de #{order.dematbox_count} scanner#{'s' if order.dematbox_count > 1} iDocus'Box"
        option.group_title = "iDo'Box - Autres"
      else
        option.group_title = if @period.duration == 12
                               'Pack Annuel - Autres'
                             else
                               "iDo’Courrier - Autres"
                             end

        option.title = 'Commande de Kit envoi courrier'
      end

      option.duration    = 1
      option.is_an_extra = true
      option.price_in_cents_wo_vat = order.price_in_cents_wo_vat

      if order.pending?
        option.group_title = 'En cours'
      elsif order.cancelled?
        option.group_title = 'Annulée'

        option.price_in_cents_wo_vat = 0.0
      end

      option
    end
  end


  def prices_list
    @prices_list ||= {
      stamp:    [5,  5],
      retriever: [5,  15],
      reduced_retriever: [3, 9],
      subscription:    [10, 30],
      return_paper:   [10, 10],
      pre_assignment: [9,  15]
    }
  end


  def package_options_price(options, type)
    price = 0.0

    options.each do |option|
      price += prices_list[option][type] * 100.0
    end

    price
  end
end
