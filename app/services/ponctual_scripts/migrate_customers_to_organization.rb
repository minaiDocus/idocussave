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

      datas.each do |data|
        data.update(organization_id: organization_id) if data.organization_id.present?
      end
    end

    user.code = 'FOO%0366'

    user.save
    user.reload

    logger_infos "[MigrationCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - new organization_id: #{user.organization_id} - End"

    #WARNING : call account number rules migration manually, because this method can't be rollback
    #migrate account number rules
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

      datas.each do |data|
        data.update(organization_id: organization_id) if data.organization_id.present?
      end
    end

    user.code = 'ACC%0366'

    user.save
    user.reload

    logger_infos "[RollbackCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - previous organization_id: #{user.organization_id} - End"
  end

  def models
    [ Pack, Pack::Report, Pack::Piece, Pack::Report::Preseizure, Pack::Report::Expense, Operation, PaperProcess, PeriodDocument, PreAssignmentDelivery, PreAssignmentExport, TempDocument, TempPack, Order ]
  end

  private

  #WARNING: This method can't be rollback
  def migrate_rules
    account_rules = Organization.find_by_code('ACC').account_number_rules.customers
    organization  = Organization.find_by_code('FOO')
    user          = User.find_by_code 'FOO%0366'

    account_rules.each do |rule|
      if rule.users.any? && rule.users.collect(&:code).include?('FOO%0366')
        new_rule                  = rule.dup
        new_rule.organization_id  = organization.id
        new_rule.users            = user
        new_rule.save

        ancient_users = rule.users
        rule.users    = ancient_users - [user]
        rule.save
      end
    end
  end

end