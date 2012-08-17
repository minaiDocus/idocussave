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

  def sortable column, title=nil, contains={}
    title ||= column.titleize
    direction = 'asc'
    icon = ''
    if column.to_s == sort_column
      direction = sort_direction == 'asc' ? 'desc' : 'asc'
      icon_direction = sort_direction == 'asc' ? 'down' : 'up'
      icon = content_tag( :i, '', class: 'icon-chevron-' + icon_direction)
    end
    options = contains
    options = options.merge(page: params[:page]) if params[:page]
    options = options.merge(per_page: params[:per_page]) if params[:per_page]
    link_to icon + title, { sort: column, direction: direction }.merge(options)
  end

  def get_documents(packs)
    Document.any_in(:pack_id => packs.distinct(:_id))
  end

  def icon_new
    content_tag :i, '', class: 'icon-plus'
  end

  def icon_show
    content_tag :i, '', class: 'icon-eye-open'
  end

  def icon_edit
    content_tag :i, '', class: 'icon-edit'
  end

  def icon_destroy
    content_tag :i, '', class: 'icon-remove'
  end

  def edit_link
    link_to icon_edit, '#', class: :edit
  end

  def icon_ok
    content_tag :i, '', class: 'icon-ok'
  end

  def icon_not_ok
    content_tag :i, '', class: 'icon-remove'
  end

  def ok_link
    link_to icon_ok, '#', class: :ok
  end

  def not_ok_link
    link_to icon_not_ok, '#', class: :not_ok
  end

  def icon_tag(value)
    value ? icon_ok : icon_not_ok
  end

  def label_ok(is_current=false)
    content_tag(:span, icon_ok, class: "label #{is_current ? 'label-success' : ''}", style: 'margin-left:2px;margin-right:2px;')
  end

  def label_not_ok(is_current=false)
    content_tag(:span, icon_not_ok, class: "label #{!is_current ? 'label-important' : ''}", style: 'margin-left:2px;margin-right:2px;')
  end

  def label_icon_tag(value)
    value ? label_ok(value) : label_not_ok(value)
  end

  def label_choice_tag(value)
    link_to(label_ok(value), '#', class: :ok) + link_to(label_not_ok(value), '#', class: :not_ok)
  end

end
