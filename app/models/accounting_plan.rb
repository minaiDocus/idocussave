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

  field :last_checked_at, type: Time

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

  def to_xml
    _address = user.paper_return_address
    builder = Nokogiri::XML::Builder.new do
      data {
        address {
          name          user.company
          contact       user.name
          address_1     _address.try(:address_1)
          address_2     _address.try(:address_2)
          zip           _address.try(:zip)
          city          _address.try(:city)
          country       _address.try(:country)
          country_code 'FR'
        }
        accounting_plans do 
          customers.each do |customer|
            wsAccounts {
              category 1
              associate customer.conterpart_account
              name customer.third_party_name
              number customer.third_party_account
              send(:'vat-account', vat_accounts.find_by_code(customer.code).try(:account_number))
            }
          end
          providers.each do |provider|
            wsAccounts {
              category 2
              associate provider.conterpart_account
              name provider.third_party_name
              number provider.third_party_account
              send(:'vat-account', vat_accounts.find_by_code(provider.code).try(:account_number))
            }
          end
        end
      }
    end
    builder.to_xml
  end

  def to_csv(header=true)
    if header
      data = [['category', 'name', 'number', 'associate', 'customer_code'].join(',')]
    else
      data = []
    end
    [[1, customers], [2, providers]].each do |category, accounts|
      accounts.each do |account|
        data << [
          category,
          account.third_party_name,
          account.third_party_account,
          account.conterpart_account,
          user.code
        ].join(',')
      end
    end
    data.join("\n")
  end
end
