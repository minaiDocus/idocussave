# -*- encoding : UTF-8 -*-
class AccountingPlan < ActiveRecord::Base
  has_many :providers, -> { where(kind: 'provider') }, class_name: 'AccountingPlanItem', as: :accounting_plan_itemable
  has_many :customers,  -> { where(kind: 'customer') }, class_name: 'AccountingPlanItem', as: :accounting_plan_itemable
  has_many :vat_accounts, class_name: 'AccountingPlanVatAccount', inverse_of: :accounting_plan

  belongs_to :user


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
            item.kind = 'provider'
            providers << item
          else
            item.kind = 'customer'
            customers << item
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
      data do

        address do
          name          user.company
          contact       user.name
          address_1     _address.try(:address_1)
          address_2     _address.try(:address_2)
          zip           _address.try(:zip)
          city          _address.try(:city)
          country       _address.try(:country)
          country_code 'FR'
        end

        accounting_plans do
          customers.each do |customer|
            wsAccounts do
              category 1
              associate customer.conterpart_account
              name customer.third_party_name
              number customer.third_party_account
              send(:'vat-account', vat_accounts.find_by_code(customer.code).try(:account_number))
            end
          end

          providers.each do |provider|
            wsAccounts do
              category 2
              associate provider.conterpart_account
              name provider.third_party_name
              number provider.third_party_account
              send(:'vat-account', vat_accounts.find_by_code(provider.code).try(:account_number))
            end
          end
        end
      end
    end

    builder.to_xml
  end


  def to_csv(header = true)
    data = if header
             [%w(category name number associate customer_code).join(',')]
           else
             []
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
