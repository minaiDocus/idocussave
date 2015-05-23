# -*- encoding : UTF-8 -*-
module ApplicationHelper
  def format_price_with_dot price_in_cents
    "%0.2f" % (price_in_cents.round/100.0)
  end

  def format_price_00 price_in_cents
    format_price_with_dot(price_in_cents).gsub(".", ",")
  end

  def format_price price_in_cents
    format_price_00(price_in_cents).gsub(/,00/, "")
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
      when 'alert'
        'alert-block'
      when 'error'
        'alert-error'
      when 'notice'
        'alert-info'
      when 'success'
        'alert-success'
      else
        type.to_s
    end
  end

  def current_url(params={})
    url_for only_path: false, params: params
  end

  def current_user_info
    if request.path.match(/organizations/)
      session[:collaborator_code].presence || 'Moi-même'
    else
      session[:user_code].presence || 'Moi-même'
    end
  end

  def logo_url
    @gray_label ? @gray_label.logo_url : image_tag('logo/tiny_logo.png', alt: 'logo')
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

  def page
    params[:page].try(:to_i) || 1
  end

  def per_page_link(number, options={})
    temp_class = (options["class"] || options[:class] || "").split()
    temp_class << 'label'
    temp_class << 'label-info' if per_page == number
    temp_class.uniq!
    temp_options = options.merge( class: temp_class )
    link_to number, params.merge( per_page: number ), temp_options
  end

  def present(object, klass=nil)
    klass ||= "#{object.class}Presenter".constantize
    presenter = klass.new(object, self)
    yield presenter if block_given?
    presenter
  end

  def provider_wish_state(provider_wish)
    klass = 'label'
    klass += ' label-success'   if provider_wish.accepted?
    klass += ' label-important' if provider_wish.rejected?
    content_tag :span, FiduceoProviderWish.state_machine.states[provider_wish.state].human_name, class: klass
  end

  def knowings_visibility_options
    [
      [t('mongoid.models.user.attributes.knowings_visibility_options.private'),    KnowingsApi::PRIVATE],
      [t('mongoid.models.user.attributes.knowings_visibility_options.restricted'), KnowingsApi::RESTRICTED],
      [t('mongoid.models.user.attributes.knowings_visibility_options.visible'),    KnowingsApi::VISIBLE]
    ]
  end

  def knowings_visibility(value)
    if value == KnowingsApi::PRIVATE
      t('mongoid.models.user.attributes.knowings_visibility_options.private')
    elsif value == KnowingsApi::RESTRICTED
      t('mongoid.models.user.attributes.knowings_visibility_options.restricted')
    elsif value == KnowingsApi::VISIBLE
      t('mongoid.models.user.attributes.knowings_visibility_options.visible')
    else
      ''
    end
  end

  def pre_assignment_date_computed_options
    [
      ["Valeur de l'organisation", -1],
      [t('no_value'),               0],
      [t('yes_value'),              1]
    ]
  end
  alias_method :auto_deliver_options, :pre_assignment_date_computed_options

  def transaction_status_for_select(default=nil)
    options = []
    t('mongoid.state_machines.fiduceo_transaction.status').each do |key, value|
      options << [value.capitalize, key]
    end
    options_for_select(options, default)
  end

  def period_type(duration)
    if duration == 1
      'Mensuel'
    elsif duration == 3
      'Trimestriel'
    elsif duration == 12
      'Annuel'
    end
  end

  def csv_outputter_options
    [
      [t('mongoid.models.csv_outputter.attributes.type'),:type],
      [t('mongoid.models.csv_outputter.attributes.client_code'),:client_code],
      [t('mongoid.models.csv_outputter.attributes.journal'),:journal],
      [t('mongoid.models.csv_outputter.attributes.period'),:period],
      [t('mongoid.models.csv_outputter.attributes.piece_number'),:piece_number],
      [t('mongoid.models.csv_outputter.attributes.original_piece_number'),:original_piece_number],
      [t('mongoid.models.csv_outputter.attributes.date'),:date],
      [t('mongoid.models.csv_outputter.attributes.period_date'),:period_date],
      [t('mongoid.models.csv_outputter.attributes.deadline_date'),:deadline_date],
      [t('mongoid.models.csv_outputter.attributes.title'),:title],
      [t('mongoid.models.csv_outputter.attributes.piece'),:piece],
      [t('mongoid.models.csv_outputter.attributes.number'),:number],
      [t('mongoid.models.csv_outputter.attributes.original_amount'),:original_amount],
      [t('mongoid.models.csv_outputter.attributes.currency'),:currency],
      [t('mongoid.models.csv_outputter.attributes.conversion_rate'),:conversion_rate],
      [t('mongoid.models.csv_outputter.attributes.credit'),:credit],
      [t('mongoid.models.csv_outputter.attributes.debit'),:debit],
      [t('mongoid.models.csv_outputter.attributes.lettering'),:lettering],
      [t('mongoid.models.csv_outputter.attributes.piece_url'),:piece_url],
      [t('mongoid.models.csv_outputter.attributes.remark'),:remark],
      [t('mongoid.models.csv_outputter.attributes.third_party'),:third_party]
    ]
  end
end
