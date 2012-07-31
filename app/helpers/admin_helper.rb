# -*- encoding : UTF-8 -*-
module AdminHelper
  def array_of_backup_function
    NeobeApi::METHOD_LIST.map{|m| [m,m.sub(/\(.*\)/,'')]}
  end
  
  def last_used_backup_function 
    if params[:function_name]
      name = NeobeApi::METHOD_LIST.select{ |m| m.match(/#{params[:function_name]}.*/) }.first rescue ""
      [name,name.sub(/\(.*\)/,'')]
    else
      []
    end
  end
  
  def users_to_tokeninput_field users
    users.map{ |user| "{id: \"#{user.id}\", name: \"#{user.email}\"}"}.join(',')
  end

  def user_codes_to_tokeninput_field users
    users.sort { |a,b|
            if a.code and b.code.blank?
              -1
            elsif a.code.blank? and b.code
              1
            elsif a.code and b.code
              a.code <=> b.code
            end
          }.
          map{ |user| "{id: \"#{user.id}\", name: \"#{user.code.presence || user.email}\"}"}.
          join(',')
  end
end
