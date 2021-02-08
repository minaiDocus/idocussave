module StatisticsManager::Subscription

  def self.generate_current_statistics
    generate_statistics_of 1.month.ago 
    generate_statistics_of Date.today
  end

  def self.generate_statistics_of(date)
    start_date    = date.to_date.beginning_of_month
    end_date      = date.to_date.end_of_month
    period_date   = date.to_date.end_of_month - 15.days

    Organization.billed.where("created_at <= ?", end_date).order(created_at: :asc).each do |organization|
      options     = { micro_package: 0, nano_package: 0, basic_package: 0, mail_package: 0, scan_box_package: 0, retriever_package: 0, mini_package: 0, annual_package: 0 }
      consumption = { upload: 0, scan: 0, dematbox_scan: 0, retriever: 0 }

      periods = Period.where(user_id: organization.customers.active_at(end_date).map(&:id)).where('start_date <= ? AND end_date >= ?', period_date, period_date)
      next if periods.empty?
      
      #options counter
      periods.each do |period|
        period.product_option_orders.each do |option|
          case option.name
            when 'micro_package_subscription'
              options[:micro_package] += 1
            when 'nano_package_subscription'
              options[:nano_package] += 1
            when 'basic_package_subscription'
              options[:basic_package] += 1
            when 'mail_package_subscription'
              options[:mail_package] += 1
            when 'dematbox_package_subscription'
              options[:scan_box_package] += 1
            when 'retriever_package_subscription'
              options[:retriever_package] += 1
            when 'mini_package_subscription'
              options[:mini_package] += 1
            when 'annual_package_subscription'
              options[:annual_package] += 1
          end
        end
      end

      #consumption counter
      user_ids = periods.map(&:user_id)
      customers = User.where(id: user_ids)
      delivery_types  = customers.joins(:temp_documents).where("temp_documents.state = 'processed' and temp_documents.created_at >= ? and temp_documents.created_at <= ?",start_date, end_date).group("delivery_type").select("temp_documents.delivery_type as delivery_type, count(distinct users.code) as count")

      delivery_types.each { |delivery| consumption[delivery.delivery_type.to_sym] = delivery.count }

      StatisticsManager.create_subscription_statistics({organization: organization, date: start_date, options: options, consumption: consumption, customers: customers.map(&:code)})

    end
  end

  def self.compare_statistics_between(first_date, second_date)
    first_date = first_date.to_date.beginning_of_month
    second_date = second_date.to_date.beginning_of_month
    compared_statistics = []
    SubscriptionStatistic.where(month: [first_date, second_date]).order(:month).group_by(&:organization_id).each_pair do |organization_id, stats|
      next unless Organization.billed.where(id: organization_id).first
      statistic = if stats.length == 2
        options = {}
        stats[1].options.keys.each do |key|
          options[key] = stats[1].options[key]
          options["#{key}_diff".to_sym] = stats[1].options[key].to_i - stats[0].options[key].to_i
        end
        SubscriptionStatistic.new(
          month: stats[1].month,
          organization_id: stats[1].organization_id,
          organization_name: stats[1].organization_name,
          organization_code: stats[1].organization_code,
          options: options,
          consumption: stats[1].consumption,
          customers: stats[1].customers,
          new_customers: stats[1].customers - stats[0].customers,
          closed_customers: stats[0].customers - stats[1].customers
        )
      else
        stats[0].dup
      end
      compared_statistics << statistic
    end
    compared_statistics
  end
end