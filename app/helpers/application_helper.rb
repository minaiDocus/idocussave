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
end
