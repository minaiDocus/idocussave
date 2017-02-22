module StatisticsManager
  def self.create_statistics(array_of_formated_statistics)
    array_of_formated_statistics.each do |statistic|
      create_statistic(statistic)
    end
  end

  def self.get_statistic(information)
    get_statistic_value(information)
  end

  def self.remove_unused_statistics
    Statistic.where.not(information: StatisticsManager::Generator.statistic_names).destroy_all
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
