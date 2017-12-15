class AddCachedAmountToPackReportPreseizures < ActiveRecord::Migration
  def change
    add_column :pack_report_preseizures, :cached_amount, :decimal, precision: 11, scale: 2

    Pack::Report::Preseizure.reset_column_information
    Pack::Report::Preseizure.transaction do
      Pack::Report::Preseizure.blocked_duplicates.each do |preseizure|
        preseizure.update(cached_amount: preseizure.entries.map(&:amount).max)
      end
    end
  end
end
