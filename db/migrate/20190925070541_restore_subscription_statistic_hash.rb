class RestoreSubscriptionStatisticHash < ActiveRecord::Migration[5.2]
  def up
    ## Not used for now because of symbol to decode in original hash
    #  SubscriptionStatistic.all.each do |i|
    #  options = i.options.to_s
    #   consumption = i.consumption.to_s

    #   i.options = JSON.parse(options.gsub('=>', ':').gsub('nil', 'null').gsub(/[:]([^:]*)[:]/, '"\1":')).to_h
    #   i.consumption = JSON.parse(consumption.gsub('=>', ':').gsub('nil', 'null').gsub(/[:]([^:]*)[:]/, '"\1":')).to_h

    #   i.save
    # end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
