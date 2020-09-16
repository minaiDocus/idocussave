class PonctualScripts::MigrateCustomers < PonctualScripts::PonctualScript
  def self.execute
    #------------------- VERY IMPORTANT : ------------------
    # re-save previous organizations groups after customers migration (from plateform website)
    # update collaborator of the customer after migration (from platteform website)
    # update customer code after migration if needed
    new().run
  end

  def self.rollback
    new().rollback
  end

  private

  def execute
    organization = Organization.find_by_code 'ACC'
    customers    = User.where(code: ['MFA%ADAPTO'])

    customers.each do |user|
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
          data.update(organization_id: organization.id) if data.organization_id.present?
        end
      end

      user.save
      user.reload

      logger_infos "[MigrationCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - new organization_id: #{user.organization_id} - End"
    end
  end

  def backup
    organization = { 'ACC%ADAPTO' => 126 }
    customers    = User.where(code: ['ACC%ADAPTO'])

    customers.each do |user|
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

      user.save
      user.reload

      logger_infos "[RollbackCustomer] - user_code: #{user.try(:my_code) || 'no_user'} - previous organization_id: #{user.organization_id} - End"
    end
  end

  def models
    [ Pack, Pack::Report, Pack::Piece, Pack::Report::Preseizure, Pack::Report::Expense, Operation, PaperProcess, PeriodDocument, PreAssignmentDelivery, PreAssignmentExport, RemoteFile, TempDocument, TempPack, Order ]
  end
end