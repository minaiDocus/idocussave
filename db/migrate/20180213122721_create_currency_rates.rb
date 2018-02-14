class CreateCurrencyRates < ActiveRecord::Migration
  def change
    create_table :currency_rates do |t|
      t.datetime :date
      t.string :exchange_from,  limit:5
      t.string :exchange_to,    limit:5
      t.string :currency_name
      t.float :exchange_rate
      t.float :reverse_exchange_rate
      t.datetime :created_at
      t.datetime :updated_at

      t.index [:date, :exchange_from, :exchange_to], name: 'index_exchange_name_date'
    end
  end
end
