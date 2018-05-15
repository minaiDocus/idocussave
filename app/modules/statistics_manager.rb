module StatisticsManager
  def self.create_statistics(array_of_formated_statistics)
    array_of_formated_statistics.each do |statistic|
      create_statistic(statistic)
    end
  end

  def self.create_subscription_statistics(datas)
    statistic   = SubscriptionStatistic.where(organization_id: datas[:organization].id, month: datas[:date]).first
    statistic ||= SubscriptionStatistic.new
    
    statistic.month             = datas[:date]
    statistic.organization_id   = datas[:organization].id
    statistic.organization_name = datas[:organization].name
    statistic.organization_code = datas[:organization].code
    statistic.options           = datas[:options]
    statistic.consumption       = datas[:consumption]
    statistic.customers         = datas[:customers]

    if statistic.persisted?
      statistic.save if statistic.changed?
    else
      statistic.save
    end
  end

  def self.get_compared_subscription_statistics(statistic_params={})
    statistics = StatisticsManager::Subscription.compare_statistics_between(statistic_params[:first_period], statistic_params[:second_period])
    if statistic_params[:organization] && statistic_params[:organization].length > 2
      statistics.select { |stat| stat.organization_name =~ /#{Regexp.quote(statistic_params[:organization])}/i }
    else
      statistics
    end
  end

  def self.get_statistic(information)
    get_statistic_value(information)
  end

  def self.remove_unused_statistics
    Statistic.where.not(information: StatisticsManager::Dashboard.statistic_names).destroy_all
  end

private

  def self.create_statistic(formated_statistic)
    if statistic = Statistic.find_by_information(formated_statistic.first)
      statistic.update(counter: formated_statistic.last)
    else
      statistic = Statistic.create(information: formated_statistic.first, counter: formated_statistic.last)
    end
  end

  def self.get_statistic_value(information)
    begin
      value = Statistic.find_by_information(information).counter.to_i
    rescue
      value = 0
    end

    value
  end
end
