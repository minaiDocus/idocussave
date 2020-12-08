# -*- encoding : UTF-8 -*-
# FIXME : whole check
module DocumentsHelper
  def linked_users_option
    has_multiple_accounts? ? accounts.map { |u| [u, u.id] } : []
  end

  def account_book_types_option
    account_book_types = []

    if @user.try(:options).try(:upload_authorized?) || @user.authorized_all_upload?
      account_book_types = @user.account_book_types.specific_mission.by_position if not @user.try(:options).try(:upload_authorized?)
      account_book_types = @user.account_book_types.by_position if @user.try(:options).try(:upload_authorized?)
    elsif @user.authorized_bank_upload?
      account_book_types = @user.account_book_types.bank_processable.by_position
    end

    account_book_types.map do |j|
      [j.name + ' ' + j.description, j.name, { 'compta-processable' => (j.compta_processable? ? '1' : '0') }]
    end
  end

  def active_users(users, year)
    users.select do |u|
      if u.created_at.year <= year
        u.active? ? true : u.inactive_at.year >= year
      else
        false
      end
    end
  end


  def filter_list_of_users(users, year)
    active_users(users, year).sort_by { |u| [u.code, u.company, u.name, u.email] }.collect { |u| [u.info, u.id] }
  end

  # build an array who's values are either a period or nil
  def annual_periods_for_user(periods)
    _periods = []
    current_month = 1
    current_period = 0

    while current_month < 13
      if periods[current_period] && periods[current_period].start_date.month == current_month
        _periods << periods[current_period]
        current_month += periods[current_period].duration
        current_period += 1
      else
        _periods << nil
        current_month += 1
      end
    end

    _periods
  end

  def active_year_for_user?(year, user, periods)
    if user.created_at.year <= year && (user.inactive_at || Time.now).year >= year && user.inactive_at.try(:month) != 1
      true
    else
      periods.compact.present?
    end
  end

  def price_of_period_by_time(periods, time)
    period = periods.select { |p| p.start_date <= time.to_date && p.end_date >= time.to_date }.first

    period.try(:price_in_cents_wo_vat) || 0
  end


  def active_clients(clients, date)
    end_date = date.end_of_month

    clients.select do |client|
      client.inactive_at.nil? || client.inactive_at > end_date ? true : false
    end
  end


  def thead(columns)
    content_tag :thead do
      content_tag :tr do
        columns.each_with_index do |c, index|
          if index < 2
            concat(content_tag(:th, c))
          else
            concat(content_tag(:th, c, style: 'text-align:right'))
          end
        end
      end
    end
  end


  def tbody(items)
    content_tag :tbody do
      items.each_with_index do |(k,v),index|
        concat(content_tag(:tr){
          concat content_tag :td, "#{index + 1}"
          concat content_tag :td, "#{l(k[:date].localtime)}"
          concat content_tag :td, "#{k[:uploaded]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:scanned]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:dematbox_scanned]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:retrieved]}", style: 'text-align:right'
          }
        )
      end
    end
  end


  def custom_table_for(columns, items)
    content_tag :table, class: 'table table-condensed table-striped' do
      thead(columns) + tbody(items)
    end
  end


  def tinformations(pack, content_width)
    content_tag :table, class: 'table table-condensed' do
      content_tag :tbody do
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Nom du document'),       width: content_width) + content_tag(:td, "#{pack.name}.pdf")
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Date de mise en ligne'), width: content_width) + content_tag(:td, l(pack.created_at).to_s)
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Date de modification'),  width: content_width) + content_tag(:td, l(pack.updated_at).to_s)
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Nombre de pages'),       width: content_width) + content_tag(:td, pack.pages_count.to_s)
        unless pack.is_fully_processed
          concat content_tag :tr, content_tag(:td, content_tag(:b, 'Nombre de pages en cours de traitement'), width: content_width) + content_tag(:td, TempPack.find_by_name(pack.name).temp_documents.not_published.sum(:pages_number).to_i.to_s)
        end
        concat content_tag :tr, content_tag(:td, content_tag(:b, 'Tags: '), width: content_width) + content_tag(:td, pack.tags.try(:join, ' '), class: 'tags')
      end
    end
  end

  def preseizures_informations(pack_or_report, content_width)
    software =  if pack_or_report.user.try(:uses?, :ibiza)
                  { human_name: 'Ibiza', name: 'ibiza' }
                elsif pack_or_report.user.try(:uses?, :exact_online)
                  { human_name: 'Exact Online', name: 'exact_online' }
                else
                  { human_name: '', name: '' }
                end

    first_created_at       = pack_or_report.preseizures.select('MIN(pack_report_preseizures.created_at) as min_created_at').first.try(:min_created_at)
    last_created_at        = pack_or_report.preseizures.select('MAX(pack_report_preseizures.created_at) as max_created_at').first.try(:max_created_at)
    last_delivery_tried_at = pack_or_report.preseizures.select('MAX(pack_report_preseizures.delivery_tried_at) as max_delivery_tried_at').first.try(:max_delivery_tried_at)

    content_tag :table, class: 'table table-condensed' do
      content_tag :tbody do
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date d'ajout de la première écriture"), width: content_width) + content_tag(:td, first_created_at ? l(first_created_at).to_s : '')
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date d'ajout de la dernière écriture"), width: content_width) + content_tag(:td, last_created_at ? l(last_created_at).to_s : '')

        if software[:name].present?
          concat content_tag :tr, content_tag(:td, content_tag(:b, "Date de dernière envoi [#{software[:human_name]}]"),  width: content_width) + content_tag(:td, last_delivery_tried_at ? l(last_delivery_tried_at).to_s : '')
          concat content_tag :tr, content_tag(:td, content_tag(:b, "Message d'erreur d'envoi [#{software[:human_name]}]") + content_tag(:span, pack_or_report.get_delivery_message_of(software[:name]).to_s, style: 'display:block'), colspan: 2)
        end
      end
    end
  end

  def html_pack_info(pack)
    columns = ['N°', 'Date', 'Télév.', 'Num.', "iDocus'Box", 'Auto.']

    contents = ''
    contents += content_tag :h4, 'Informations'
    contents += content_tag :div, tinformations(pack, 220)

    if pack.preseizures.any?
      contents += content_tag :h4, 'Ecritures Comptables'
      contents += content_tag :div, preseizures_informations(pack, 220)
    end

    contents += content_tag :h4, 'Historique des ajouts de pages'
    contents += content_tag :div, custom_table_for(columns, pack.content_historic)
    content_tag :div, contents, style: 'width: 100%'
  end

  def html_report_info(report)
    contents = ''
    contents += content_tag :h4, 'Ecritures Comptables'
    contents += content_tag :div, preseizures_informations(report, 220)
    content_tag :div, contents, style: 'width: 100%'
  end

  def html_piece_view(piece)
    contents = ''
    contents += content_tag :h4, "Pièce n° #{piece.position} - #{piece.name}"
    contents += content_tag :div, content_tag(:iframe, "", :src => piece.cloud_content_object.url, :class => "piece_view", :style => "width:100%; min-height:550px; max-height: 600px")
    content_tag :div, contents, style: 'width: 750px; padding: 10px;z-index:200'
  end

  def quarterly_of_month(month)
    if month < 4
      1
    elsif month < 7
      2
    elsif month < 10
      3
    else
      4
    end
  end


  def options_for_period(period_service = @period_service, time = Time.now)
    current_time = time

    period_duration = period_service.period_duration

    results = [[period_option_label(period_duration, time), 0]]

    if period_service.prev_expires_at.nil? || period_service.prev_expires_at > Time.now
      period_service.authd_prev_period.times do |i|
        current_time -= period_duration.month

        results << [period_option_label(period_duration, current_time), i + 1]
      end
    end

    results
  end


  def period_option_label(period_duration, time)
    case period_duration
    when 1
      time.strftime('%m %Y')
    when 3
      "T#{quarterly_of_month(time.month)} #{time.year}"
    when 12
      time.year.to_s
    end
  end

  def file_upload_users_list
    if @user.organization.specific_mission
      @user.organization.customers.active.order(code: :asc)
    else
      @file_upload_users_list ||= accounts.active.order(code: :asc).select do |user|
        user.authorized_upload?
      end
    end
  end

  def file_upload_params
    if has_multiple_accounts?
      result = {}

      file_upload_users_list.each do |user|
        period_service              = Billing::Period.new user: user
        journals                    = []
        journals_compta_processable = []

        if user.authorized_all_upload? || user.try(:options).try(:upload_authorized?)
          journals = user.account_book_types.order(name: :asc).map do |j|
            j.name + ' ' + j.description
          end
          journals_compta_processable  = user.account_book_types.order(name: :asc).map do |j|
            j.name if j.compta_processable?
          end.compact
        elsif user.authorized_bank_upload?
          journals = user.account_book_types.bank_processable.map{|j| j.name + ' ' + j.description}
          journals_compta_processable = user.account_book_types.bank_processable.map{|j| j.name if j.compta_processable? }
        end

        hsh = {
          journals: journals,
          journals_compta_processable: journals_compta_processable,
          periods:  options_for_period(period_service),
          is_analytic_used: (user.try(:ibiza).try(:ibiza_id?) && user.uses?(:ibiza) && user.try(:ibiza).try(:compta_analysis_activated?))
        }

        if period_service.prev_expires_at
          hsh[:message] = {
            period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
            date:   l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
          }
        end

        result[user.code] = hsh
      end

      result
    else
      {}
    end
  end

  def verif_debit_credit_somme_of(preseizure_entries)
    debit_value = credit_value = 0

    preseizure_entries.each do |entry|
      #NOTE : Don't use entry.amount.to_f or to_i here, debit_value and credit_value can't be converted before addition
      if entry.type == 1
        debit_value += entry.amount || 0
      else
        credit_value += entry.amount || 0
      end
    end

    debit_value.to_f != credit_value.to_f
  end
end