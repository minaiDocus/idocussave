class PonctualScripts::MigrateCustomersToOrganization < PonctualScripts::PonctualScript
  def self.execute
    #IMPORTANT : re-save organizations groups after customers migration (from plateforme website)
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    organization = Organization.find_by_code 'FOO'
    user         = User.find_by_code 'ACC%0366'

    logger_infos "[MigrationCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - organization_id: #{user.organization_id} - Start"
    user.organization_id = organization.id

    models.each do |mod|
      if mod.to_s == 'Pack'
        datas = mod.unscoped.where(owner_id: user.id)
      else
        datas = mod.unscoped.where(user_id: user.id)
      end

      logger_infos mod.to_s + " => " + datas.size.to_s + " new organization : " + organization.id.to_s

      datas.update_all(organization_id: organization.id)
    end

    user.code = 'FOO%0366'

    user.save
    user.reload

    logger_infos "[MigrationCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - new organization_id: #{user.organization_id} - End"
  end

  def backup
    organization = { 'FOO%0366' => 1 }
    user         = User.find_by_code 'FOO%0366'

    organization_id = organization[user.code.to_s]

    logger_infos "[MigrationCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - organization_id: #{user.organization_id} - Start"
    user.organization_id = organization_id

    models.each do |mod|
      if mod.to_s == 'Pack'
        datas = mod.unscoped.where(owner_id: user.id)
      else
        datas = mod.unscoped.where(user_id: user.id)
      end

      logger_infos mod.to_s + " => " + datas.size.to_s + " rollback organization : " + organization_id.to_s

      datas.update_all(organization_id: organization_id)
    end

    user.code = 'ACC%0366'

    user.save
    user.reload

    logger_infos "[RollbackCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - previous organization_id: #{user.organization_id} - End"
  end

  def models
    [ Pack, Pack::Report, Pack::Piece, Pack::Report::Preseizure, Pack::Report::Expense, Operation, Order, PaperProcess, PeriodDocument, Period, PreAssignmentDelivery, PreAssignmentExport, RemoteFile, Subscription, TempDocument, TempPack ]
  end
end