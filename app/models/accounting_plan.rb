# -*- encoding : UTF-8 -*-
class AccountingPlan
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user
  embeds_many :providers,    class_name: 'AccountingPlanItem', as: :accounting_plan_itemable
  embeds_many :customers,    class_name: 'AccountingPlanItem', as: :accounting_plan_itemable
  embeds_many :vat_accounts, class_name: 'AccountingPlanVatAccount', inverse_of: :accounting_plan

  accepts_nested_attributes_for :providers,    allow_destroy: true
  accepts_nested_attributes_for :customers,    allow_destroy: true
  accepts_nested_attributes_for :vat_accounts, allow_destroy: true

  def import(file, type)
    items = type == 'providers' ? providers : customers
    begin
      ::CSV.foreach(file.path, headers: true, col_sep: ';') do |row|
        attrs = row.to_hash.slice('NOM_TIERS', 'COMPTE_TIERS', 'COMPTE_CONTREPARTIE', 'CODE_TVA')
        attrs = { third_party_name: attrs['NOM_TIERS'], third_party_account: attrs['COMPTE_TIERS'], conterpart_account: attrs['COMPTE_CONTREPARTIE'], code: attrs['CODE_TVA'] }
        if (item = items.find_by_name(row['NOM_TIERS']))
          item.update(attrs)
        else
          item = AccountingPlanItem.new(attrs)
          if type == 'providers'
            self.providers << item
          else
            self.customers << item
          end
          item.save
        end
      end
      true
    rescue
      false
    end
  end
end
