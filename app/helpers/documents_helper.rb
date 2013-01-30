# -*- encoding : UTF-8 -*-
module DocumentsHelper
  
  def linked_users_option
    user_ids = Pack.any_in(:user_ids => [@user.id]).not_in(:owner_id => [@user.id]).distinct(:owner_id)
    users = User.any_in(:_id => user_ids)

    users = users.sort do |a,b|
      if a.code && b.code && a.code != b.code
        a.code <=> b.code
      elsif a.company && b.company && a.company != b.company
        a.company <=> b.company
      elsif a.first_name && b.first_name && a.last_name && b.last_name && (a.first_name + " " + a.last_name) != (b.first_name + " " + b.last_name)
        (a.first_name + " " + a.last_name) <=> (b.first_name + " " + b.last_name)
      else
        a.email <=> b.email
      end
    end

    users.collect do |u|
      name = ""
      name +=  u.code + " - " if !u.code.blank?
      name +=  u.company + " - " if !u.company.blank?
      name += u.email
      [name,u.id]
    end
  end
  
  def account_book_types_option
    @user.account_book_types.by_position.map do |u|
      description = u.description.blank? ? "" : " " + u.description
      [u.name + description, u.name]
    end
  end
  
  def tags_of(document, tags)
    tags.select { |tag| tag[:user_id] == @user.id and tag[:document_id] == document.id }.first.try(:name)
  end
  
  def filter_list_of_users(users)
    sorted_users = users.sort do |a,b|
      if a.code and a.company and a.first_name and a.last_name and a.email and b.code and b.company and b.first_name and b.last_name and b.email
        if a.code != b.code
          a.code <=> b.code
        elsif a.company != b.company
          a.company <=> b.company
          elsif (a.first_name + " " + a.last_name) != (b.first_name + " " + b.last_name)
          (a.first_name + " " + a.last_name) <=> (b.first_name + " " + b.last_name)
        else
          a.email <=> b.email
        end
      else
        1
      end
    end
    sorted_users.collect { |u| [u.info,u.id] }
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

  def active_periods?(user, periods)
    result = periods.select { |e| e != nil }.count > 0
    (!user.is_inactive && result) ? true : false
  end
  
  def price_of_period_by_time(periods, time)
    periods.select { |period| period.start_at <= time and period.end_at >= time }.
    first.
    try(:price_in_cents_wo_vat) || 0
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
        columns.each do |c|
          concat(content_tag(:th, c, style: 'text-align:right'))
        end
      end
    end
  end

  def tbody(items)
    content_tag :tbody do
      items.each_with_index do |(k,v),index|
        concat(content_tag(:tr){
          concat content_tag :td, "#{index + 1}"
          concat content_tag :td, "#{k[:date].strftime("%d/%m/%Y")}", style: 'text-align:right'
          concat content_tag :td, "#{k[:uploaded]}", style: 'text-align:right'
          concat content_tag :td, "#{k[:scanned]}", style: 'text-align:right'
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
  
  def tinformations(pack, original_document, pages, content_width)   
    content_tag :table, class: 'table table-condensed' do
      content_tag :tbody do
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Nom du document"),       width: content_width) + content_tag(:td, "#{pack.name}.pdf")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date de mise en ligne"), width: content_width) + content_tag(:td, "#{pack.created_at.strftime("%d/%m/%Y")}")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Date de modification"),  width: content_width) + content_tag(:td, "#{pack.updated_at.strftime("%d/%m/%Y")}")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Nombre de pages"),       width: content_width) + content_tag(:td, "#{pages.count}")
        concat content_tag :tr, content_tag(:td, content_tag(:b, "Tags: "),                width: content_width) + content_tag(:td, "#{tags_of(original_document,@all_tags)}")
      end
    end
  end
  
  def html_pack_info(pack, original_document, pages)
    columns = [ "N°","Date","Téléversées","Numérisées"]
    
    contents = ""
    contents += content_tag :h4, "Informations"
    contents += content_tag :div, tinformations(pack, original_document, pages, 120)
    contents += content_tag :h4, "Historique des ajouts de pages"
    contents += content_tag :div, custom_table_for(columns,pack.historic)
    content_tag :div, contents
  end

  def file_type_to_deliver_options
    [
        ['Tous', ExternalFileStorage::ALL_TYPES],
        ['PDF', ExternalFileStorage::PDF],
        ['TIFF', ExternalFileStorage::TIFF]
    ]
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
end
