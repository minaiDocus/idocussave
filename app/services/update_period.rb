# -*- encoding : UTF-8 -*-
class UpdatePeriod
  def initialize(period)
    @period       = period
    @subscription = period.subscription
  end

  def execute
    @period.with_lock(timeout: 3, retries: 30, retry_sleep: 0.1) do
      @subscription.reload
      @period.reload
      @period.duration = @subscription.period_duration
      copyable_keys.each do |key|
        @period[key] = @subscription[key]
      end
      @period.product_option_orders = options
      if @period.save
        PeriodBillingService.new(@period).fill_past_with_0
        UpdatePeriodPriceService.new(@period).execute
      end
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
      _options = extra_options
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
      selected_options = []
      is_base_package_priced = false
      type = @subscription.period_duration == 1 ? 0 : 1
      if @subscription.is_basic_package_active
        is_base_package_priced = true
        price = package_options_price([:subscription, :pre_assignment], type)
        option = ProductOptionOrder.new
        option.name                  = 'basic_package_subscription'
        option.group_title           = "iDo'Basique"
        option.title                 = 'Téléchargement + Pré-saisie comptable'
        option.price_in_cents_wo_vat = price
        option.duration              = 0
        option.quantity              = 1
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
        option.name                  = 'mail_package_subscription'
        option.group_title           = "iDo'Courrier"
        option.title                 = 'Envoi par courrier A/R + Pré-saisie comptable'
        option.price_in_cents_wo_vat = price
        option.duration              = 0
        option.quantity              = 1
        selected_options << option

        if @subscription.is_stamp_active
          option = ProductOptionOrder.new
          option.name                  = 'mail_package-stamp'
          option.group_title           = "iDo'Courrier - Option"
          option.title                 = 'Tamponnage du papier en sortie de numérisation'
          option.price_in_cents_wo_vat = package_options_price([:stamp], type)
          option.duration              = 0
          option.quantity              = 1
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
        option.name                  = 'dematbox_package_subscription'
        option.group_title           = "iDo'Box"
        option.title                 = "Scan par iDocus'Box + Pré-saisie comptable"
        option.price_in_cents_wo_vat = price
        option.duration              = 0
        option.quantity              = 1
        selected_options << option

        if @subscription.is_blank_page_remover_active
          option = ProductOptionOrder.new
          option.name                  = 'dematbox_package-blank_page_deletion'
          option.group_title           = "iDo'Box - Option"
          option.title                 = 'Reconnaissance et élimination des pages blanches'
          option.price_in_cents_wo_vat = package_options_price([:blank_page_deletion], type)
          option.duration              = 0
          option.quantity              = 1
          selected_options << option
        end
      end
      if @subscription.is_retriever_package_active
        option = ProductOptionOrder.new
        option.name                  = 'retriever_package_subscription'
        option.group_title           = "iDo'FacBanque"
        option.title                 = 'Récupération banque + factures sur Internet'
        option.price_in_cents_wo_vat = price
        option.duration              = 0
        option.quantity              = 1
        selected_options << option
      end
      unless @subscription.is_pre_assignment_active
        option = ProductOptionOrder.new
        option.name                  = 'all_package-disable_pre_assignment'
        option.group_title           = 'Tous forfaits'
        option.title                 = 'Suppression pré-saisie comptable des factures'
        option.price_in_cents_wo_vat = -package_options_price([:pre_assignment], type)
        option.duration              = 0
        option.quantity              = 1
        selected_options << option
      end
      selected_options
    end
  end

  def annual_subscription_option
    option = ProductOptionOrder.new
    option.name                  = 'annual_package_subscription'
    option.group_title           = 'Pack Annuel'
    option.title                 = "Envoi courrier + téléchargement + iDo'FacBanque + Pré-saisie comptable"
    option.price_in_cents_wo_vat = 19900.0
    option.duration              = 0
    option.quantity              = 1
    option
  end

  def journals_option
    additionnal_journals = @subscription.number_of_journals - 5
    if additionnal_journals > 0
      option = ProductOptionOrder.new
      option.name                  = 'excess_journals'
      option.group_title           = 'Tous forfaits'
      if additionnal_journals == 1
        option.title               = "#{additionnal_journals} journal comptable supplémentaire"
      else
        option.title               = "#{additionnal_journals} journaux comptables supplémentaires"
      end
      option.price_in_cents_wo_vat = additionnal_journals * 100.0
      option.duration              = 0
      option.quantity              = additionnal_journals
      option
    end
  end

  def extra_options
    @subscription.options.by_position.map do |extra_option|
      option = ProductOptionOrder.new
      option.name                  = 'extra_option'
      option.group_title           = 'Autres'
      option.title                 = extra_option.name
      option.price_in_cents_wo_vat = extra_option.price_in_cents_wo_vat
      option.duration              = extra_option.period_duration
      option.is_an_extra           = true
      option
    end
  end

  def order_options
    @period.orders.asc(:created_at).map do |order|
      option = ProductOptionOrder.new
      option.name = 'extra_option'
      if order.dematbox?
        option.group_title = "iDo'Box - Autres"
        option.title = "Commande de #{order.dematbox_count} scanner#{'s' if order.dematbox_count > 1} iDocus'Box"
      else
        if @period.duration == 12
          option.group_title = "Pack Annuel - Autres"
        else
          option.group_title = "iDo’Courrier - Autres"
        end
        option.title = 'Commande de Kit envoi courrier'
      end
      option.price_in_cents_wo_vat = order.price_in_cents_wo_vat
      option.duration = 1
      option.is_an_extra = true
      option
    end
  end

  def prices_list
    @prices_list ||= {
      subscription:        [10, 30],
      pre_assignment:      [9,  15],
      return_paper:        [10, 10],
      stamp:               [5,  5],
      blank_page_deletion: [1,  1],
      retriever:           [5,  15]
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
