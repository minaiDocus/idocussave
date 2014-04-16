# -*- encoding : UTF-8 -*-
class FiduceoProviderWishObserver < Mongoid::Observer
  def before_create(provider_wish)
    client = Fiduceo::Client.new provider_wish.user.fiduceo_id
    params = {
      name:                   provider_wish.name,
      url:                    provider_wish.url,
      login:                  provider_wish.login,
      pass:                   provider_wish.password,
      custom_connection_info: provider_wish.custom_connection_info,
      description:            provider_wish.description
    }
    client.put_provider_wish params
    # TODO implement failure management
  end
end
