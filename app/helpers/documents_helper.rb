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
  
  def tags_of document
    DocumentTag.where(:user_id => current_user.id, :document_id => document.id).first.name rescue ""
  end
  
  def filter_list_of_users users
    sorted_users = users.sort do |a,b|
      if a.code != b.code
        a.code <=> b.code
      elsif a.company != b.company
        a.company <=> b.company
        elsif (a.first_name + " " + a.last_name) != (b.first_name + " " + b.last_name)
        (a.first_name + " " + a.last_name) <=> (b.first_name + " " + b.last_name)
      else
        a.email <=> b.email
      end
    end
    sorted_users.collect do |u|
      name = ""
      name +=  u.code + " - " if !u.code.blank?
      name +=  u.company + " - " if !u.company.blank?
      name += u.email
      [name,u.id]
    end
  end
  
  def format_user user
    name = user.code.blank? ? "" : user.company.blank? ? user.code : "#{user.code} - "
    name += user.company.blank? ? "" : user.company
    name
  end
  
  def annual_periods_for_user user, scan_subscriptions, year=Time.now.year
    periods = []
    subscriptions = scan_subscriptions.of_user(user).for_year(@year).asc(:start_at)
    current_date = Time.local(year,1,15,0,0,0)
    while current_date.year == year
      subscriptions.each do |subscription|
        while subscription.end_at > current_date and current_date.year == year
          period = subscription.find_period(current_date)
          if period
            periods << period
            current_date += period.duration.month
          else
            periods << nil
            current_date += 1.month
          end
        end
      end
      while current_date.year == year
        periods << nil
        current_date += 1.month
      end
    end
    periods
  end
end
