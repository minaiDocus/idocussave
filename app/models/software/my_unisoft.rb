# -*- encoding : UTF-8 -*-
class Software::MyUnisoft < ApplicationRecord
  belongs_to :owner, polymorphic: true

  attr_encrypted :api_token, random_iv: true

  def configured?
    name.present? && society_id.present? && member_id.present?  	
  end

  def auto_deliver?
    if self.owner_type == 'Organization'
      auto_deliver == 1
    else

    end
  end
end