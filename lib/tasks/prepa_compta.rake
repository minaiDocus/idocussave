# -*- encoding : UTF-8 -*-
namespace :prepa_compta do
  desc 'Update accounting plan'
  task :update_accounting_plan => [:environment] do
    puts "[#{Time.now}] maintenance:prepa_compta:update_accounting_plan - START"
    UpdateAccountingPlan.execute
    PrepaCompta::GenerateMapping.execute
    puts "[#{Time.now}] maintenance:prepa_compta:update_accounting_plan - END"
  end
end
