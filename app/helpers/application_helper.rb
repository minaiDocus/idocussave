# -*- encoding : UTF-8 -*-
module ApplicationHelper
  include StaticList::Helpers

  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",").gsub(/,00/, "")
  end
  
  def format_price_00 price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(".", ",")
  end
  
  def format_price_with_dot price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros).gsub(/.00/, "")
  end

  def format_tiny_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents/100.0

    if price_in_euros.round_at(2) == price_in_euros.round_at(4)
      ("%0.2f" % price_in_euros).gsub(".", ",").gsub(/,00/, "")
    else
      ("%0.4f" % price_in_euros).gsub(".", ",").gsub(/,0000/, "")
    end
  end

  def icon_ban_circle
    content_tag :i, '', class: 'icon-ban-circle'
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

  def icon_move
    content_tag :i, '', class: 'icon-move'
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
  
  def icon_globe
    content_tag :i, '', class: 'icon-globe'
  end

  def twitterized_type(type)
    case type
      when :alert
        "alert-block"
      when :error
        "alert-error"
      when :notice
        "alert-info"
      when :success
        "alert-success"
      else
        type.to_s
    end
  end

  def current_url(params={})
    url_for only_path: false, params: params
  end

  def current_user_info
    session[:acts_as].presence || "Moi-même"
  end

  def logo_url
    @gray_label ? @gray_label.logo_url : asset_path('logo/tiny_logo.png')
  end

  def site_url
    @gray_label ? @gray_label.site_url : SITE_DEFAULT_URL
  end

  def sortable(column, title=nil, contains={})
    title ||= column.titleize
    direction = 'asc'
    icon = ''
    if column.to_s == sort_column
      direction = sort_direction == 'asc' ? 'desc' : 'asc'
      icon_direction = sort_direction == 'asc' ? 'down' : 'up'
      icon = content_tag( :i, '', class: 'icon-chevron-' + icon_direction)
    end
    options = params.merge(contains)
    link_to icon + title, options.merge( sort: column, direction: direction )
  end

  def per_page
    params[:per_page].try(:to_i) || 20
  end

  def per_page_link(number, options={})
    temp_class = (options["class"] || options[:class] || "").split()
    temp_class << 'label'
    temp_class << 'label-info' if per_page == number
    temp_class.uniq!
    temp_options = options.merge( class: temp_class )
    link_to number, params.merge( per_page: number ), temp_options
  end
end
