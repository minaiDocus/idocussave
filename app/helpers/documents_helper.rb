module DocumentsHelper
  
  def linked_users_option
    user_ids = Pack.any_in(:user_ids => [current_user.id]).not_in(:owner_id => [current_user.id]).distinct(:owner_id)
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
    current_user.account_book_types.by_position.map do |u|
      description = u.description.blank? ? "" : " " + u.description
      [u.name + description, u.name]
    end
  end
  
  def tags_of document, tags
    tags.select { |tag| tag[:user_id] == current_user.id and tag[:document_id] == document.id }.first.try(:name)
  end
  
  def filter_list_of_users users
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
    sorted_users.collect do |u|
      name = []
      name << u.code if !u.code.blank?
      name << u.company if !u.company.blank?
      name << u.email
      name = name.join(" - ")
      [name,u.id]
    end
  end
  
  def format_user user
    name = user.code.blank? ? "" : user.company.blank? ? user.code : "#{user.code} - "
    name += user.company.blank? ? "" : user.company
    name
  end
  
  def annual_periods_for_user user, scan_subscriptions, all_periods, year=Time.now.year
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
end
