# -*- encoding: utf-8 -*-
class System::DatabaseCleaner
  def clear_all
    clear_mcf
    clear_retrieved_data
    clear_currency_rate
    clear_job_processing
  end

  private

    def clear_mcf
      ## Destroy all McfDocument records when 'created_at < ?', 1.years.ago
      McfDocument.where('created_at < ?', 1.years.ago).destroy_all
    end

    def clear_retrieved_data
      ## Remove all oldest RetriedData when 'created_at < ?', 1.month.ago
      RetrievedData.where('created_at < ?', 1.month.ago).destroy_all
    end

    def clear_currency_rate
      ## Truncate CurrencyRate table when Time.now.month == 6, Time.now.day == 1 and Time.now.hour == 1
        ActiveRecord::Base.connection.execute("TRUNCATE #{CurrencyRate.table_name}") if (Time.now.month.to_i % 6 == 0) && Time.now.day.to_i == 1
    end

    def clear_job_processing
      ## Destroy all JobProcessing when records 'created_at < ?', 1.month.ago
      JobProcessing.where('started_at < ?', 1.month.ago).finished.destroy_all
    end
end