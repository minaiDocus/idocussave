# -*- encoding : UTF-8 -*-
class SubscriptionForm
  def initialize(subscription, requester=nil)
    @subscription = subscription
    @requester    = requester
  end

  def submit(params)
    @product_metadata = params['product']
    params['period_duration'] = @subscription.period_duration if params['period_duration'].nil?
    if product && product.period_duration == params['period_duration'].to_i
      _params = params.dup.tap { |p| p.delete('product') }
      _params[:options] = get_options
      if _params[:options].any? || @subscription.organization
        UpdateSubscriptionService.new(@subscription, _params, @requester).execute
      else
        false
      end
    else
      false
    end
  end

  def permit_all_options
    !Settings.is_subscription_lower_options_disabled
  end

  def product
    @product ||= Product.where(_id: @product_metadata['id']).first
  end

  def get_options
    if product && (permit_all_options || product.period_duration == @subscription.period_duration)
      group_metadatas = @product_metadata[@product_metadata['id']] || []
      options = []

      group_metadatas.each do |group_metadata|
        group = product.product_groups.where(_id: group_metadata[0]).first
        if group && (group.position < 1000 || @requester.try(:is_admin))
          group_metadata[1].each do |option_id|
            option = group.product_options.where(_id: option_id).first
            if option
              if @requester.try(:is_admin) || permit_all_options || !group.is_option_dependent
                options << option
              else
                selected_option = @subscription.options.where(product_group_id: group_metadata[0]).first
                if !selected_option || option.position > selected_option.position
                  options << option
                else
                  options << selected_option
                end
              end
            end
          end
        end
      end

      unless @requester.try(:is_admin) || permit_all_options
        options += @subscription.options.select do |option|
          !option.product_group.is_option_dependent
        end
        options.uniq!
      end

      unless @requester.try(:is_admin)
        options += extra_options
        options.uniq!
      end
      options
    else
      false
    end
  end

  def extra_options
    @subscription.options.select do |option|
      option.group_position >= 1000
    end
  end
end
