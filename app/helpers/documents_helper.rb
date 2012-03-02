module DocumentsHelper
  
  def linked_users_option
    order_ids = current_user.orders.collect{|o| o.id} rescue []

    users = Pack.where(:user_ids => current_user.id).not_in(:order_id => order_ids).entries.collect{|p| p.order.user}.uniq

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

    users.collect{|u| [(u.company ? u.company+" - "+u.email : u.email),u.id]}
  end
  
  def account_book_types_option
    prescriber = current_user.prescriber
    if prescriber
      prescriber.account_book_types.by_position.map do |u|
        description = u.description.blank? ? "" : " " + u.description
        [u.name + description, u.name]
      end
    else
      []
    end
  end
  
  def tags_of document
    Iconv.iconv('ISO-8859-1', 'UTF-8', DocumentTag.where(:user_id => current_user.id, :document_id => document.id).first.name).join() rescue ""
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
    sorted_users.collect do |user|
      name = user.code.blank? ? "" : user.company.blank? ? user.code : "#{user.code} - "
      name += user.company.blank? ? "" : user.first_name.blank? ? user.company : "#{user.company} - "
      name += user.first_name.blank? ? "" : user.last_name.blank? ? user.first_name : "#{user.first_name} #{user.last_name}"
      [name, user.id]
    end
  end
  
  def format_user user
    name = user.code.blank? ? "" : user.company.blank? ? user.code : "#{user.code} - "
    name += user.company.blank? ? "" : user.first_name.blank? ? user.company : "#{user.company} - "
    name += user.first_name.blank? ? "" : user.last_name.blank? ? user.first_name : "#{user.first_name} #{user.last_name}"
    name
  end
  
end
