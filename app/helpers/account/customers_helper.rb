# frozen_string_literal: true

module Account::CustomersHelper
  def software_uses(software_name)
    case software_name
    when 'ibiza'
      @organization.try(:ibiza).try(:used?) && !@customer.uses?(:exact_online) && !@customer.uses?(:my_unisoft)
    when 'exact_online'
      @organization.try(:exact_online).try(:used?) && !@customer.uses?(:ibiza) && !@customer.uses?(:my_unisoft)
    when 'my_unisoft'
      @organization.try(:my_unisoft).try(:used?) && !@customer.uses?(:ibiza) && !@customer.uses?(:exact_online)
    end
  end
end