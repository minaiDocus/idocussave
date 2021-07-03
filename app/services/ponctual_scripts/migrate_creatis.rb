class PonctualScripts::MigrateCreatis < PonctualScripts::PonctualScript
  def self.execute(options={})
    new(options).run
  end

  def self.rollback(options={})
    new(options).rollback
  end

  private

  def execute
    #[IMPORTANT] : account number rules must be migrate before customer migration
    migrate_accounts_rules  unless @options[:rules_only]
    migrate_collaborators   unless @options[:customers_only]
    migrate_customers       unless @options[:collaborators_only]
  end

  def backup
    migrate_accounts_rules(true)  unless @options[:rules_only]
    migrate_collaborators(true)   unless @options[:customers_only]
    migrate_customers(true)       unless @options[:collaborators_only]
  end

  def creatis_id
   { 'CG' => Organization.find_by_code('CG').id }
  end

  def models
    [ Pack, Pack::Report, Pack::Piece, Pack::Report::Preseizure, Pack::Report::Expense, Operation, PaperProcess, PeriodDocument, PreAssignmentDelivery, PreAssignmentExport, RemoteFile, TempDocument, TempPack, Order ]
  end

  def creatis
    ['CG']
  end

  def jegard_id
    return @jegard_id if @jegard_id.present?

    jegard = Organization.find_by_code 'JC'
    @jegard_id = jegard.id
  end

  def previous_org_of(user)
    org_code  = user.code.split('%')[0]
    creatis_id[org_code.strip.to_s].to_i
  end

  def migrate_customers(rollback = false)
    #[IMPORTANT] : account number rules must be migrate before customer migration
    #[IMPORTANT] : suspend organization after customers migration OR re-save organizations groups after customers migration (from plateforme website)
    did_rollback = false

    creatis.each do |code|
      next if did_rollback

      organization = Organization.find_by_code code
      curr_org_id = rollback ? jegard_id : organization.id

      customers = User.unscoped.where(organization_id: curr_org_id, is_prescriber: false)
      next_id = jegard_id

      customers.each do |user|
        current_org  = user.organization_id
        next_id      = previous_org_of(user) if rollback

        logger_infos("Can't rollback user : #{user.id} - #{user.code}") if rollback && next_id <= 0

        if(!rollback || (rollback && next_id > 0))
          logger_infos("======================= START - #{user.code} - org: #{current_org} ======================")

          models.each do |mod|
            if mod.to_s == 'Pack'
              datas = mod.unscoped.where(owner_id: user.id)
            else
              datas = mod.unscoped.where(user_id: user.id)
            end

            if next_id > 0
              logger_infos("Migration #{mod.to_s} : #{datas.size.to_s} : #{user.id.to_s} - #{user.code.to_s} from => #{current_org.to_s} to => #{next_id.to_s}")
              user.organization_id = next_id
              datas.each do |data|
                data.update(organization_id: next_id) if data.organization_id.present?
              end
            end
          end

          logger_infos("======================= END - #{user.code} - to : #{next_id} ======================")
          user.save
        end
      end

      did_rollback = true if rollback
    end
  end

  def migrate_collaborators(rollback = false)
    if rollback
      members = Member.where(organization_id: jegard_id)
      members.each(&:destroy)
    else
      members = Member.where(organization_id: [71]).select(:user_id).distinct

      collaborators = User.where(id: members.collect(&:user_id))

      collaborators.each do |user|
        next if user.memberships.where(organization_id: jegard_id).first || !user.email.match(/[@]jegardcreatis[.]fr/)
        member = user.memberships.first

        if !member
          logger_infos("======================= NO MEMBER - #{user.id} - #{user.email} ======================")
          next
        end

        logger_infos("======================= START - #{user.id} - #{member.code} ======================")

        user_code = member.code.split('%')[1].strip

        clone_member                  = member.dup
        clone_member.code             = "JC%#{user_code.to_s}"
        clone_member.organization_id  = jegard_id

        clone_member.save

        logger_infos("======================= END - #{user.id} - #{clone_member.code} ======================")
      end
    end
  end

  def migrate_accounts_rules(rollback = false)
    #[IMPORTANT] : account number rules must be migrate before customer migration
    if rollback
      jegard = Organization.find jegard_id
      account_number_rules = jegard.account_number_rules
      account_number_rules.each(&:destroy)
    else
      creatis_id.each do |org|
        organization = Organization.find_by_code org
        account_rules = organization.account_number_rules

        logger_infos("======================= START - Org - #{organization.code} - rules : #{account_rules.size} ======================")
        account_rules.each do |rule|
          new_rule = rule.dup
          new_rule.organization_id = jegard_id
          if rule.users.any?
            new_rule.users = rule.users
          else
            new_rule.users = organization.customers.active
          end

          new_rule.save
        end
        logger_infos("======================= END - Org - #{organization.code} ======================")
      end
    end
  end
end