# -*- encoding : UTF-8 -*-
# Updates period with last subscription informations
class Billing::UpdatePeriod
  def initialize(period, options={})
    @period          = period
    @subscription    = period.subscription
    @options         = options
  end

  def execute
    @period.with_lock(timeout: 3, retries: 30, retry_sleep: 0.1) do
      @subscription.reload

      @period.duration = @subscription.period_duration

      if !@period.organization
        copyable_keys.each do |key|
          @period[key] = @subscription[key]
        end

        @period.set_current_packages(@options.try(:[], :renew_packages))
      end

      freezed_options = @period.product_option_orders.is_frozen.map{|opt| opt.dup}
      @period.product_option_orders.destroy_all
      @period.product_option_orders = options + freezed_options

      Billing::UpdatePeriodPrice.new(@period).execute if @period.save # updates period pricing if sucess
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
      _options = [base_options, journals_option, order_options, extra_options, bank_accounts_options, operation_options, digitize_options]
    end

    _options.flatten.compact.each_with_index do |option, index|
      option.group_position = option.position = index + 1
    end
  end

  def base_options
    if @subscription.is_package?('ido_annual')
      annual_subscription_option
    else
      # type = @subscription.period_duration == 1 ? 0 : 1

      selected_options = []
      # is_base_package_priced = false

      @period.get_active_packages.each do |package|
        package_infos = Subscription::Package.infos_of(package)

        option = ProductOptionOrder.new

        option.title    = package_infos[:label]
        option.name     = package_infos[:name]
        option.duration = 0
        option.quantity = 1
        option.group_title = package_infos[:group]
        option.is_to_be_disabled = @subscription.is_to_be_disabled_package?(package)
        option.price_in_cents_wo_vat = Subscription::Package.price_of(package) * 100.0

        selected_options << option

        selected_options << remaining_months_option(package) if (package == :ido_micro || package == :ido_nano) && remaining_months_option.present?
        #selected_options << mini_remaining_months_option  if package == :ido_mini && mini_remaining_months_option.present?
      end

      @period.get_active_options.each do |_p_option|
        next if _p_option.to_s == 'pre_assignment_option' && !@subscription.is_pre_assignment_really_active

        option_infos = Subscription::Package.infos_of(_p_option)

        option = ProductOptionOrder.new

        reduced = (@subscription.retriever_price_option == :retriever)? false : true

        option.title    = option_infos[:label]
        option.name     = option_infos[:name]
        option.duration = 0
        option.quantity = 1
        option.group_title = option_infos[:group]
        option.is_to_be_disabled = @subscription.is_to_be_disabled_option?(_p_option)
        option.price_in_cents_wo_vat = Subscription::Package.price_of(_p_option, reduced) * 100.0

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

  def remaining_months_option(package=:ido_micro)
    return @remaining_months_option unless @remaining_months_option.nil?

    @remaining_months_option = ''

    months_remaining = difference_in_months(@period.end_date, @subscription.end_date) - 1

    if @subscription.user.inactive? && months_remaining > 0
      option       = ProductOptionOrder.new
      package_text = ""

      case package
        when :ido_micro
          package_text = "iDo'Micro"
        when :ido_nano
          package_text = "iDo'Nano"
      end

      option.title       = "#{package_text} : engagement #{months_remaining} mois restant(s)"
      option.name        = 'extra_option'
      option.duration    = 1
      option.group_title = 'Autres'
      option.is_an_extra = true
      option.price_in_cents_wo_vat = Subscription::Package.price_of(package) * 100.0 * months_remaining

      @remaining_months_option = option
    end

    @remaining_months_option
  end

  def mini_remaining_months_option
    return @mini_remaining_months_option unless @mini_remaining_months_option.nil?

    @mini_remaining_months_option = ''
    months_remaining = difference_in_months(@period.end_date, @subscription.end_date) - 1

    if @subscription.user.inactive? && months_remaining > 0 && ['GAP%STAYHOME'].include?(@subscription.user.code)
      option = ProductOptionOrder.new

      option.title       = "iDo'Mini : engagement #{months_remaining} mois restant(s)"
      option.name        = 'extra_option'
      option.duration    = 1
      option.group_title = 'Autres'
      option.is_an_extra = true
      option.price_in_cents_wo_vat = Subscription::Package.price_of(:ido_mini) * 100.0 * months_remaining

      @mini_remaining_months_option = option
    end

    @mini_remaining_months_option
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
    discount = Billing::DiscountBilling.new(@subscription.organization)

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
    is_manual_paper_set_order = CustomUtils.is_manual_paper_set_order?(@period.user.organization)

    @period.orders.order(created_at: :asc).map do |order|
      next if order.paper_set? && is_manual_paper_set_order

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
        order_paper_set_exist = true
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

  def difference_in_months(date1, date2)
    return 0 if date1.blank? || date2.blank?

    month_count = (date2.try(:year) == date1.try(:year)) ? (date2.month - date1.month) : (12 - date1.month + date2.month)
    month_count = (date2.try(:year) == date1.try(:year)) ? (month_count + 1) : (((date2.year - date1.year - 1 ) * 12) + (month_count + 1))
    month_count
  end


  def bank_accounts_options
    return nil if not @period.user

    bank_ids = @period.user.operations.where("DATE_FORMAT(created_at, '%Y%m') = #{@period.start_date.strftime("%Y%m")}").pluck(:bank_account_id).uniq

    excess_bank_accounts = @period.user.bank_accounts.where(id: bank_ids).size - 2
    option_infos = Subscription::Package.infos_of(:retriever_option)

    if excess_bank_accounts > 0
      option = ProductOptionOrder.new

      option.name        = 'excess_bank_accounts'
      option.group_title = option_infos[:group]

      if excess_bank_accounts == 1
        option.title = "#{excess_bank_accounts} compte bancaire supplémentaire"
      else
        option.title = "#{excess_bank_accounts} comptes bancaires supplémentaires"
      end

      option.duration = 0
      option.quantity = excess_bank_accounts
      option.price_in_cents_wo_vat = excess_bank_accounts * 200.0

      option
    end
  end

  def operation_options
    return nil if not @period.user

    billing_options = []
    option_infos = Subscription::Package.infos_of(:retriever_option)
    reduced      = (@subscription.retriever_price_option == :retriever)? false : true
    amount       = Subscription::Package.price_of(:retriever_option, reduced) * 100.0

    operations_dates = @period.user.operations.where.not(processed_at: nil).where("is_locked = false AND DATE_FORMAT(created_at, '%Y%m') = #{@period.start_date.strftime('%Y%m')}").map{|ope| ope.date.strftime('%Y%m')}.uniq
    period_dates     = @period.user.periods.map{|_period| _period.start_date.strftime('%Y%m')}.uniq

    rest = operations_dates - period_dates

    rest.sort.each do |value_date|
      if value_date.to_s.match(/^[0-9]{6}$/) && value_date.to_i >= 202001 && value_date.to_i < @period.start_date.strftime("%Y%m").to_i
        previous_orders = @period.user.periods.collect(&:product_option_orders).flatten.compact
        jump = false
        title = "Opérations bancaires mois de #{I18n.l(Date.new(value_date.to_s[0..3].to_i, value_date.to_s[4..-1].to_i), format: '%B')} #{value_date.to_s[0..3].to_i}"

        previous_orders.each do |order|
          next if jump

          jump = true if title == order.title
        end

        next if jump

        option = ProductOptionOrder.new

        option.name        = 'billing_previous_operations'
        option.group_title = option_infos[:group]

        begin
          option.title = title
        rescue => e
          p "----->#{e.to_s}---->" + value_date.to_s
          next
        end

        option.duration = 0
        option.quantity = 1
        option.price_in_cents_wo_vat = amount

        billing_options << option
      end
    end

    billing_options
  end

  def digitize_options
    # is_manual_paper_set_order = CustomUtils.is_manual_paper_set_order?(@period.user.organization)
    digitize_option = []

    if @period.subscription.is_package?('digitize_option')
      option_infos = Subscription::Package.infos_of(:digitize_option)

      scanned_sheets_size = @period.scanned_sheets

      if scanned_sheets_size > 0
        #### ------- Scanned sheet Option -------- ####
        ss_option = ProductOptionOrder.new

        ss_option.name        = 'scanned_sheets'
        ss_option.group_title = option_infos[:group]

        ss_option.title = "#{scanned_sheets_size} feuille(s) numérisée(s)"

        ss_option.duration = 0
        ss_option.quantity = scanned_sheets_size
        ss_option.price_in_cents_wo_vat = scanned_sheets_size * 10.0

        digitize_option << ss_option

        #### --------- Pack size Option -------- ####
        pack_names = @period.user.paper_processes.where('created_at >= ? and created_at <= ?', @period.start_date, @period.end_date).where(type: 'scan').select(:pack_name).distinct
        pack_size  = pack_names.collect(&:pack_name).size

        if pack_size > 0
          ps_option = ProductOptionOrder.new

          ps_option.name        = 'scanned_sheets'
          ps_option.group_title = option_infos[:group]

          ps_option.title = "#{pack_size} pochette(s) scannée(s)"

          ps_option.duration = 0
          ps_option.quantity = pack_size
          ps_option.price_in_cents_wo_vat = pack_size * 100.0

          digitize_option << ps_option
        end
      end
    end

    digitize_option
  end
end