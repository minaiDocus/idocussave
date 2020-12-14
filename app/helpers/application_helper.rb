# -*- encoding : UTF-8 -*-
# FIXME : whole check
module ApplicationHelper
  def logo_url
    image_path('logo/tiny_logo.png')
  end


  def format_price_with_dot(price_in_cents)
    '%0.2f' % (price_in_cents.round / 100.0)
  end


  def format_price_00(price_in_cents)
    format_price_with_dot(price_in_cents).tr('.', ',')
  end


  def format_price(price_in_cents)
    format_price_00(price_in_cents).gsub(/,00/, '')
  end


  def format_tiny_price(price_in_cents)
    price_in_euros = price_in_cents.blank? ? '' : price_in_cents / 100.0

    if price_in_euros.round_at(2) == price_in_euros.round_at(4)
      ('%0.2f' % price_in_euros).tr('.', ',').gsub(/,00/, '')
    else
      ('%0.4f' % price_in_euros).tr('.', ',').gsub(/,0000/, '')
    end
  end

  def user_login_tag
    label = glyphicon("person", { class: "mr-sm-2" })
    label += 'Identifiant (E-mail)'
  end

  def user_password_tag
    label = glyphicon("lock-locked", { class: "mr-sm-2" })
    label += 'Mot de passe'
  end

  def glyphicon(icon, options={})
    style = ''
    style += options[:size].present? ? "width: #{options[:size]}px; height: #{options[:size]}px;" : ''
    style += options[:color].present? ? "fill: #{options[:color]};" : ''
    style += options[:style] if options[:style].present?

    klass = options[:class].to_s

    content_tag 'svg', content_tag('use', '', 'xlink:href'=>"/assets/open-iconic.min.svg##{icon}", class: "icon icon-#{icon}"), viewBox: "0 0 8 8", class: "oi-icon #{klass} #{options[:color].present? ? 'colored' : ''}", style: style
  end

  def icon_ban_circle
    content_tag :i, '', class: 'icon-ban-circle'
  end


  def icon_download
    content_tag :i, '', class: 'icon-download'
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


  def icon_refresh
    content_tag :i, '', class: 'icon-refresh'
  end


  def edit_link
    link_to icon_edit, '#', class: :edit
  end


  def icon_ok
    glyphicon('check')
  end


  def icon_not_ok
    glyphicon('x')
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


  def label_ok(is_current = false)
    content_tag(:span, icon_ok, class: "badge #{is_current ? 'badge-success' : ''}", style: 'margin-left:2px;margin-right:2px;')
  end


  def label_not_ok(is_current = false)
    content_tag(:span, icon_not_ok, class: "badge #{!is_current ? 'badge-danger' : ''}", style: 'margin-left:2px;margin-right:2px;')
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
      'alert-warning'
    when 'error'
      'alert-danger'
    when 'notice'
      'alert-info'
    when 'success'
      'alert-success'
    else
      type.to_s
    end
  end


  def current_url(params = {})
    url_for only_path: false, params: params
  end


  def current_user_info
    session[:user_code].presence || 'Moi-même'
  end


  def sortable(column, title = nil, contains = {})
    title ||= column.titleize
    direction = 'asc'
    icon = ''

    if column.to_s == sort_column
      direction = sort_direction == 'asc' ? 'desc' : 'asc'
      icon_direction = sort_direction == 'asc' ? 'bottom' : 'top'
      icon = glyphicon('chevron-'+icon_direction) + " "
    end

    options = params.merge(contains)

    link_to icon + title, options.permit!.merge(sort: column, direction: direction)
  end


  def per_page
    per_page = params[:per_page] || 20
    per_page.to_i
  end


  def page
    page = params[:page] || 1
    page.to_i
  end


  def per_page_link(number, options = {})
    temp_class = (options['class'] || options[:class] || '').split
    temp_class << 'page-link-badge'
    temp_class << 'badge'
    temp_class << 'badge-info' if per_page == number
    temp_class.uniq!

    temp_options = options.merge(class: temp_class)

    link_to number, params.permit!.merge(per_page: number), temp_options
  end


  def present(object, klass = nil)
    klass ||= "#{object.class}Presenter".constantize

    presenter = klass.new(object, self)

    yield presenter if block_given?

    presenter
  end


  def new_provider_request_state(new_provider_request)
    klass = 'badge fs-origin'
    klass_plus = ' badge-secondary'
    klass_plus = ' badge-success'   if new_provider_request.accepted?
    klass_plus = ' badge-danger' if new_provider_request.rejected?
    klass += klass_plus
    content_tag :span, NewProviderRequest.state_machine.states[new_provider_request.state].human_name, class: klass
  end


  def knowings_visibility_options
    [
      [t('activerecord.models.user.attributes.knowings_visibility_options.private'),    KnowingsApi::PRIVATE],
      [t('activerecord.models.user.attributes.knowings_visibility_options.restricted'), KnowingsApi::RESTRICTED],
      [t('activerecord.models.user.attributes.knowings_visibility_options.visible'),    KnowingsApi::VISIBLE]
    ]
  end


  def knowings_visibility(value)
    if value == KnowingsApi::PRIVATE
      t('activerecord.models.user.attributes.knowings_visibility_options.private')
    elsif value == KnowingsApi::RESTRICTED
      t('activerecord.models.user.attributes.knowings_visibility_options.restricted')
    elsif value == KnowingsApi::VISIBLE
      t('activerecord.models.user.attributes.knowings_visibility_options.visible')
    else
      ''
    end
  end


  def pre_assignment_date_computed_options
    [
      ["Paramètres du cabinet (appliquer la règle définie dans les paramètres du cabinet)", -1],
      ["Date d’origine (la facture sera saisie à sa date d’origine)", 0],
      ["Date de la période iDocus (la facture sera saisie au 1er jour du mois/trimestre en cours dans lequel la facture est déposée dans iDocus, exemple: une facture de janvier déposée le 15 novembre sera saisie au 1er novembre)", 1]
    ]
  end


  def auto_deliver_options
    [
      ["Paramètres du cabinet", -1],
      [t('no_value'),            0],
      [t('yes_value'),           1]
    ]
  end
  alias :activate_compta_analytic_options :auto_deliver_options

  def operation_processing_options
    [
      ["Paramètres du cabinet", -1],
      [t('no_value'),            0],
      [t('yes_value'),           1]
    ]
  end

  def operation_value_date_options
    [
      ["Paramètres du cabinet", -1],
      [t('no_value'),            0],
      [t('yes_value'),           1]
    ]
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


  def csv_descriptor_directive_options
    [
      [t('activerecord.models.csv_descriptor.attributes.client_code'), :client_code],
      [t('activerecord.models.csv_descriptor.attributes.journal'), :journal],
      [t('activerecord.models.csv_descriptor.attributes.pseudonym'), :pseudonym],
      [t('activerecord.models.csv_descriptor.attributes.period'), :period],
      [t('activerecord.models.csv_descriptor.attributes.piece_number'), :piece_number],
      [t('activerecord.models.csv_descriptor.attributes.original_piece_number'), :original_piece_number],
      [t('activerecord.models.csv_descriptor.attributes.date'), :date],
      [t('activerecord.models.csv_descriptor.attributes.period_date'), :period_date],
      [t('activerecord.models.csv_descriptor.attributes.deadline_date'), :deadline_date],
      [t('activerecord.models.csv_descriptor.attributes.operation_label'), :operation_label],
      [t('activerecord.models.csv_descriptor.attributes.piece'), :piece],
      [t('activerecord.models.csv_descriptor.attributes.number'), :number],
      [t('activerecord.models.csv_descriptor.attributes.original_amount'), :original_amount],
      [t('activerecord.models.csv_descriptor.attributes.currency'), :currency],
      [t('activerecord.models.csv_descriptor.attributes.conversion_rate'), :conversion_rate],
      [t('activerecord.models.csv_descriptor.attributes.credit'), :credit],
      [t('activerecord.models.csv_descriptor.attributes.debit'), :debit],
      [t('activerecord.models.csv_descriptor.attributes.complete_unit'), :complete_unit],
      [t('activerecord.models.csv_descriptor.attributes.partial_unit'), :partial_unit],
      [t('activerecord.models.csv_descriptor.attributes.lettering'), :lettering],
      [t('activerecord.models.csv_descriptor.attributes.piece_url'), :piece_url],
      [t('activerecord.models.csv_descriptor.attributes.remark'), :remark],
      [t('activerecord.models.csv_descriptor.attributes.third_party'), :third_party],
      [t('activerecord.models.csv_descriptor.attributes.tags'), :tags],
      ['Autre', :other]
    ]
  end


  def csv_descriptor_format_options
    [
      ['AAAA/MM'],
      ['MM/AAAA'],
      ['AAAA/MM/JJ'],
      ['JJ/MM/AAAA'],
      ['AA/MM'],
      ['MM/AA'],
      ['AA/MM/JJ'],
      ['JJ/MM/AA']
    ]
  end

  def markdown_render(content)
    @markdown ||= Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    @markdown.render content
  end

  def has_multiple_accounts?
    accounts.size > 1 || @user.is_prescriber || @user.is_guest
  end
end
