# -*- encoding : UTF-8 -*-
module DocumentsHelper
  def linked_users_option(user)
    if user.is_prescriber && user.organization
      user.customers.asc(:code).map { |u| [u, u.id] }
    else
      []
    end
  end

  def account_book_types_option
    @user.account_book_types.by_position.map do |u|
      description = u.description.blank? ? "" : " " + u.description
      [u.name + description, u.name]
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
    active_users(users,year).
    sort_by { |u| [u.code,u.company,u.name,u.email] }.
    collect { |u| [u.info,u.id] }
  end

  def annual_periods_for_user(user, all_periods)
    current_month = 1
    current_period = 0
    periods = []
    temp_period = all_periods.select { |period| period[:user_id] == user[:_id] }.sort { |a,b| a.start_at <=> b.start_at }
    while current_month < 13
      if temp_period[current_period] and temp_period[current_period].start_at.month == current_month
        periods << temp_period[current_period]
        current_month += temp_period[current_period].duration
        current_period += 1
      else
        periods << nil
        current_month += 1
      end
    end
    periods
  end

  def active_periods?(user, periods, year)
    if user.created_at.year <= year && (user.inactive_at || Time.now).year >= year && user.inactive_at.try(:month) != 1
      true
    else
      periods.compact.size != 0
    end
  end

  def price_of_period_by_time(periods, time, is_customer=true)
    period = periods.select { |period| period.start_at <= time and period.end_at >= time }.first
    if is_customer
      period.try(:price_in_cents_wo_vat) || 0
    elsif period
      period.product_option_orders.select { |o| o.group_position >= 1000 }.sum(&:price_in_cents_wo_vat)
    else
      0
    end
  end

  def active_clients(clients, date)
    end_date = date.end_of_month
    clients.select do |client|
      if client.inactive_at.nil?
        true
      elsif client.inactive_at > end_date
        true
      else
        false
      end
    end
  end

  def thead(columns)
    content_tag :thead do
      content_tag :tr do
        columns.each_with_index do |c,index|
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
          concat content_tag :td, "#{l(k['date'].localtime)}"
          concat content_tag :td, "#{k['uploaded']}", style: 'text-align:right'
          concat content_tag :td, "#{k['scanned']}", style: 'text-align:right'
          concat content_tag :td, "#{k['dematbox_scanned']}", style: 'text-align:right'
          concat content_tag :td, "#{k['fiduceo']}", style: 'text-align:right'
          }
        )
      end
    end
  end

  def custom_table_for(columns,items)
    content_tag :table, class: 'table table-condensed table-striped' do
      thead(columns) + tbody(items)
    end
  end

  def tinformations(pack, content_width)
    content_tag :table, class: 'table table-condensed' do
      content_tag :tbody do
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Nom du document"),       width: content_width) + content_tag(:td, "#{pack.name}.pdf")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date de mise en ligne"), width: content_width) + content_tag(:td, "#{l(pack.created_at)}")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date de modification"),  width: content_width) + content_tag(:td, "#{l(pack.updated_at)}")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Nombre de pages"),       width: content_width) + content_tag(:td, "#{pack.pages_count}")
        unless pack.is_fully_processed
          concat content_tag :tr, content_tag(:td, content_tag(:b, "Nombre de pieces"),    width: content_width) + content_tag(:td, "#{TempPack.find_by_name(pack.name).temp_documents.not_published.count}")
        end
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Tags: "),                width: content_width) + content_tag(:td, "#{pack.tags.join(' ')}", class: 'tags')
      end
    end
  end

  def html_pack_info(pack)
    columns = ['N°', 'Date', 'Télév.', 'Num.', "iDocus'Box", "Auto."]

    contents = ""
    contents += content_tag :h4, "Informations"
    contents += content_tag :div, tinformations(pack, 120)
    contents += content_tag :h4, "Historique des ajouts de pages"
    contents += content_tag :div, custom_table_for(columns,pack.content_historic)
    content_tag :div, contents
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

  def options_for_period(period_service=@period_service, time=Time.now)
    current_time = time
    period_duration = period_service.period_duration
    results = [[period_option_label(period_duration, time), 0]]
    if period_service.prev_expires_at.nil? || period_service.prev_expires_at > Time.now
      period_service.authd_prev_period.times do |i|
        current_time -= period_duration.month
        results << [period_option_label(period_duration, current_time), i+1]
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

  def file_upload_params
    if @user.organization && @user.is_prescriber
      result = {}
      @user.customers.active.each do |customer|
        period_service = PeriodService.new user: customer
        hsh = {
          journals: customer.account_book_types.asc(:name).map(&:name),
          periods:  options_for_period(period_service)
        }
        if period_service.prev_expires_at
          hsh.merge!({
            message: {
              period: period_option_label(period_service.period_duration, Time.now - period_service.period_duration.month),
              date:   l(period_service.prev_expires_at, format: '%d %B %Y à %H:%M')
            }
          })
        end
        result[customer.code] = hsh
      end
      result
    else
      {}
    end
  end
end
