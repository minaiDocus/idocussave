class Pack::Report::Preseizure::Account < ApplicationRecord
  self.inheritance_column = :_type_disabled

  TTC = 1
  HT  = 2
  TVA = 3

  has_many   :entries   , class_name: 'Pack::Report::Preseizure::Entry', inverse_of: :account, dependent: :destroy
  belongs_to :preseizure, class_name: 'Pack::Report::Preseizure'       , inverse_of: :accounts

  scope :ttc, -> { where(type: TTC) }
  scope :ht,  -> { where(type: HT) }
  scope :vat, -> { where(type: TVA) }

  accepts_nested_attributes_for :entries


  def self.get_type(txt)
    if txt == "TTC"
      1
    elsif txt == "HT"
      2
    elsif txt == "TVA"
      3
    else
      nil
    end
  end

  # get all accounts wich have the same rules as "self" ( is used for autocompletion )
  def get_similar_accounts
    accounts_name   = []
    preseizure      = self.preseizure
    accounting_plan = preseizure.user.accounting_plan
    entry           = self.entries.first

    if preseizure.piece
      journal = preseizure.report.journal({ name_only: false })
      if journal
        compta_type = journal.compta_type

        fetch_customer = entry.type == Pack::Report::Preseizure::Entry::DEBIT && compta_type == 'VT'
        fetch_provider = entry.type == Pack::Report::Preseizure::Entry::CREDIT && compta_type == 'AC'

        accounts_name << journal.anomaly_account

        if fetch_provider || fetch_customer
          accounts_name << journal.meta_account_number

          if fetch_customer
            accounts_name << accounting_plan.active_customers.collect(&:third_party_account)
          else
            accounts_name << accounting_plan.active_providers.collect(&:third_party_account)
          end
        else
          accounts_name << journal.meta_charge_account

          if entry.type == Pack::Report::Preseizure::Entry::DEBIT && compta_type == 'AC'
            accounts_name << accounting_plan.active_providers.select(:conterpart_account).distinct.collect(&:conterpart_account)
          elsif entry.type == Pack::Report::Preseizure::Entry::CREDIT && compta_type == 'VT'
            accounts_name << accounting_plan.active_customers.select(:conterpart_account).distinct.collect(&:conterpart_account)
          end
        end

        if self.type == Pack::Report::Preseizure::Account::TVA
          accounts_name << journal.get_vat_accounts

          accounts_name << accounting_plan.vat_accounts.collect(&:account_number)
        end
      end
    elsif preseizure.operation
      match_rules  = []
      operation    = preseizure.operation
      bank_account = operation.try(:bank_account)
      rules        = preseizure.user.account_number_rules
      target       = operation.credit? ? 'credit' : 'debit'

      match_rules = rules.select{ |rule| rule.rule_target == 'both' || rule.rule_target == target }.collect(&:third_party_account) if rules

      accounts_name << bank_account.try(:accounting_number) || 512_000
      accounts_name << bank_account.try(:temporary_account) || 471_000
      accounts_name << match_rules

      if operation.credit?
        accounts_name << accounting_plan.active_providers.collect(&:third_party_account)
      else #debit
        accounts_name << accounting_plan.active_customers.collect(&:third_party_account)
      end
    end

    accounts_name = accounts_name.flatten
    accounts_name = accounts_name.uniq
    accounts_name.compact
  end
end
