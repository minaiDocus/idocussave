class PonctualScripts::MigrateVolantis < PonctualScripts::PonctualScript
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

    # migrate_ibiza           unless @options[:ibiza_only]
    migrate_mcf             unless @options[:mcf_only]
  end

  def backup
    migrate_accounts_rules(true)  unless @options[:rules_only]
    migrate_collaborators(true)   unless @options[:customers_only]
    migrate_customers(true)       unless @options[:collaborators_only]

    # migrate_ibiza(true)           unless @options[:ibiza_only]
    migrate_mcf(true)             unless @options[:mcf_only]
  end

  def volantis_group_ids
    return @volantis_group_ids unless @volantis_group_ids

    @volantis_group_ids = { 'VOL' => Organization.find_by_code('VOL').id }
  end

  def models
    [ Pack, Pack::Report, Pack::Piece, Pack::Report::Preseizure, Pack::Report::Expense, Operation, PaperProcess, PeriodDocument, PreAssignmentDelivery, PreAssignmentExport, RemoteFile, TempDocument, TempPack, Order ]
  end

  def volantis_group
    ['VOL']
  end

  def dac_id
    return @dac_id if @dac_id.present?

    dac = Organization.find_by_code 'DAC'
    @dac_id = dac.id
  end

  def previous_org_of(user)
    org_code  = user.code.split('%')[0]
    volantis_group_ids[org_code.strip.to_s].to_i
  end

  def migrate_customers(rollback = false)
    #[IMPORTANT] : account number rules must be migrate before customer migration
    #[IMPORTANT] : suspend organization after customers migration OR re-save organizations groups after customers migration (from plateforme website)
    did_rollback = false

    volantis_group.each do |code|
      next if did_rollback

      organization = Organization.find_by_code code
      curr_org_id = rollback ? dac_id : organization.id

      customers = User.unscoped.where(organization_id: curr_org_id, is_prescriber: false).where(code: customer_codes)
      next_id = dac_id

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
      members = Member.where(organization_id: dac_id)
      members.each(&:destroy)
    else
      members = Member.where(organization_id: 76).where(code: user_codes).select(:user_id).distinct

      collaborators = User.where(id: members.collect(&:user_id))

      collaborators.each do |user|
        next if user.memberships.where(organization_id: dac_id).first
        member = user.memberships.first

        if !member
          logger_infos("======================= NO MEMBER - #{user.id} - #{user.email} ======================")
          next
        end

        logger_infos("======================= START - #{user.id} - #{member.code} ======================")

        user_code = member.code.split('%')[1].strip

        clone_member                  = member.dup
        clone_member.code             = "DAC%#{user_code.to_s}"
        clone_member.organization_id  = dac_id

        clone_member.save

        logger_infos("======================= END - #{user.id} - #{clone_member.code} ======================")
      end
    end
  end

  def migrate_accounts_rules(rollback = false)
    #[IMPORTANT] : account number rules must be migrate before customer migration
    if rollback
      volantis = Organization.find dac_id
      account_number_rules = volantis.account_number_rules
      account_number_rules.each(&:destroy)
    else
      volantis_group.each do |org|
        organization = Organization.find_by_code org
        account_rules = organization.account_number_rules

        logger_infos("======================= START - Org - #{organization.code} - rules : #{account_rules.size} ======================")
        account_rules.each do |rule|
          new_rule = rule.dup
          new_rule.organization_id = dac_id
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

  def migrate_mcf(rollback = false)
    if rollback
      mcf = Organization.find_by_code('DAC').mcf_settings
      mcf.organization_id = volantis_group_ids['VOL'] if mcf
    else
      mcf = Organization.find_by_code('VOL').mcf_settings
      mcf.organization_id = volantis_id if mcf
    end

    mcf.save
  end

  def user_codes
    ["VOL%ANWY",
     "VOL%LAMO",
     "VOL%ERBA",
     "VOL%VALE",
     "VOL%SYTH",
     "VOL%CHBA",
     "VOL%RABO",
     "VOL%SOPE",
     "VOL%LB",
     "VOL%KD",
     "VOL%TBM",
     "VOL%LG",
     "VOL%SL",
     "VOL%BC",
     "VOL%MB",
     "VOL%YN",
     "VOL%NB"
    ]
  end

  def customer_codes
    ["VOL%3WASSO",
    "VOL%ACTOURISM",
    "VOL%ADEMF",
    "VOL%AGILEIT",
    "VOL%ANAGLYPHE",
    "VOL%AQUAPROIDF",
    "VOL%ARTENE",
    "VOL%AUREMAT",
    "VOL%BAREMAT",
    "VOL%BONNEGRAINE",
    "VOL%BOULPLATEAU",
    "VOL%BOURBOUX",
    "VOL%BROSSE",
    "VOL%CASSAR",
    "VOL%CHEVALIER",
    "VOL%CRISTASEYA",
    "VOL%DAC",
    "VOL%DANSECHESN",
    "VOL%DEFITEC",
    "VOL%DESAUW",
    "VOL%DOUDOU",
    "VOL%DUBBLE",
    "VOL%DVPTIMMO",
    "VOL%EDITRIOMPHE",
    "VOL%EGEKIP",
    "VOL%ELMELHAOUI",
    "VOL%EMCONSEIL",
    "VOL%EXCILONE",
    "VOL%FCE28",
    "VOL%FILSGEORGES",
    "VOL%FMIMMOBIL",
    "VOL%GLACIER",
    "VOL%GRANDIR",
    "VOL%GROUPETOILE",
    "VOL%HARASCOTES",
    "VOL%HUBTOBEE",
    "VOL%ICM",
    "VOL%IMEMAIA",
    "VOL%IPHCONSEIL",
    "VOL%LBCONSULT",
    "VOL%LIBRANT",
    "VOL%LIBRCHIMER",
    "VOL%LUMINOL",
    "VOL%MAIAAUTISME",
    "VOL%MALEYTH",
    "VOL%MEDIAVOTE",
    "VOL%MONTIAUTO",
    "VOL%MUCH",
    "VOL%OLIVERAEM",
    "VOL%OPTICHAMP",
    "VOL%ORSONVILLE",
    "VOL%PIERRELAYE",
    "VOL%PLK",
    "VOL%PROMAUTO",
    "VOL%PRUVOST",
    "VOL%QUALIFERS",
    "VOL%QUANTICS",
    "VOL%RAVION",
    "VOL%RESEURO",
    "VOL%RUMILLYAUTO",
    "VOL%SANNOISAUTO",
    "VOL%SAV",
    "VOL%SCIDOMORSON",
    "VOL%SILLAUTO",
    "VOL%SOLEILHET",
    "VOL%SQB",
    "VOL%STAGESAC",
    "VOL%STRATDUR",
    "VOL%TAVERNIER",
    "VOL%TEXTO",
    "VOL%TML",
    "VOL%TMLH",
    "VOL%VERSALIS",
    "VOL%VOLENTIS"]
  end
end