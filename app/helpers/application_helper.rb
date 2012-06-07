
module ApplicationHelper
  include StaticList::Helpers

  #FIXME No dry see in application_controller
  #we need it for mailer to !
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

  def  tunnel_address_default_choice? current_order, address, billing
    if current_user.addresses.count > 1
      address_attr = billing ? :billing_address : :shipping_address
      if current_order.send(address_attr).present?
        default_address = current_order.send(address_attr)
      elsif current_user.orders.any? && current_user.orders.order_by(:created_at).last.send(address_attr).present?
        default_address = current_user.orders.last.send(address_attr)
      elsif current_user.addresses.any? && current_user.addresses.first
        default_address = current_user.addresses.first
      else
        default_address = nil
      end
      return address.same_location?(default_address)
    else
      return true
    end
  end

  def waybill_error(error_code)
    case error_code
      when "17" then
        "Le bordereau de cette commande a déjà été généré"
      when "30" then
        "Un problème technique est intervenue veuillez réessayer d'ici quelques minutes"
      else
        "Un erreur a eu lieu pendant la transmission de votre dossier"
    end
  end

  def footer_pages()
    pages = Page.in_footer.by_footer_position
    return pages, pages.count()
  end

  def link_to_remove_fields(name, f)
    f.hidden_field(:_destroy) + link_to_function(name, "remove_fields(this)")
  end
  
  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object) do |builder|
      render :partial => association.to_s.singularize + "_fields", :locals => {:f => builder}
    end
    link_to_function image_tag("web-app-theme/application_edit.png", :alt => "Ajouter un #{name}") + "Ajouter un #{name}", "add_fields(this, '#{association}', '#{h(escape_javascript(fields))}')", :class => "button"
  end
  
  def active_clients clients, date
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
end
