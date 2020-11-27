# frozen_string_literal: true

module Account::CustomersHelper
  def software_uses(software_name)
    case software_name
    when 'ibiza'
      @organization.try(:ibiza).try(:used?) && !@customer.uses_exact_online? && !@customer.uses_my_unisoft?
    when 'exact_online'
      @organization.is_exact_online_used && !@customer.uses_ibiza? && !@customer.uses_my_unisoft?
    when 'my_unisoft'
      @organization.try(:my_unisoft).try(:organization_used) && !@customer.uses_ibiza? && !@customer.uses_exact_online?
    end
  end
end