# -*- encoding : UTF-8 -*-
module KnowingsApi
  PRIVATE    = 0
  RESTRICTED = 1
  VISIBLE    = 2


  def self.visibility(value)
    if value == RESTRICTED
      I18n.t('activerecord.models.user.attributes.knowings_visibility_options.restricted').downcase
    elsif value == VISIBLE
      I18n.t('activerecord.models.user.attributes.knowings_visibility_options.visible').downcase
    else
      I18n.t('activerecord.models.user.attributes.knowings_visibility_options.private').downcase
    end
  end
end
