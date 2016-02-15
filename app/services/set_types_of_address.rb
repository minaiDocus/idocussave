# -*- encoding : UTF-8 -*-
class SetTypesOfAddress
  def initialize(address)
    @address = address
  end

  def execute
    set_is_for('is_for_billing')
    set_is_for('is_for_paper_return')
    set_is_for('is_for_paper_set_shipping')
    set_is_for('is_for_dematbox_shipping')
    @address.locatable.addresses.each(&:save)
  end

  def set_is_for(attribute)
    if @address.send(attribute).in? ['1', true]
      @address.locatable.addresses.each do |address|
        address.send(attribute + '=', false)
      end
      @address.send(attribute + '=', true)
    else
      @address.send(attribute + '=', false)
    end
  end
end
