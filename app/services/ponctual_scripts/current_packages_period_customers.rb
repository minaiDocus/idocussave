class PonctualScripts::CurrentPackagesPeriodCustomers < PonctualScripts::PonctualScript
  def self.execute(period_date)
    new({period: period_date}).run
  end

  private

  def execute
    period_date = @options[:period] # period_date = "2020-08-03"

    periods = Period.where("created_at >= ? AND created_at <= ? ", period_date.to_date.beginning_of_month, period_date.to_date.end_of_month)

    file_path = Rails.root.join('files', "current_packages_customers_#{period_date.to_date.strftime("%Y_%m")}.csv")
    file = File.open(file_path, 'w')
    file.write("period_id; subscription_id; user_code; current_packages; duration \n")

    periods.each do |period|
      active_packages = period.get_active_packages
      user = period.user

      next unless user && user.still_active? && active_packages.present? && active_packages.size > 1

      file.write("#{period.id.to_s}; #{period.subscription_id}; #{user.code.to_s}; #{active_packages.join(',')}; #{period.duration.to_s}\n")

      logger_infos("period_id: #{period.id.to_s}; subscription_id: #{period.subscription_id}, user_code: #{user.code}; current_packages: #{active_packages}; duration: #{period.duration};")
      sleep 3
    end

    file.close
  end
end
