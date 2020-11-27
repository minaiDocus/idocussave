# -*- encoding : UTF-8 -*-
class Software::MyUnisoft < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :organization, optional: true

  attr_encrypted :api_token, random_iv: true

  before_save do |my_unisoft|
    if my_unisoft.user_used && !my_unisoft.organization_used
      my_unisoft.organization_used = true
      my_unisoft.organization      = my_unisoft.user.organization
   	end
  end

  def configured?
  	name.present? && society_id.present? && member_id.present?  	
  end

  def auto_deliver?  	
  	customer_auto_deliver ? customer_auto_deliver : user.organization.try(:my_unisoft).try(:organization_auto_deliver)
  end
end