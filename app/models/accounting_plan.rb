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
          item.update_attributes(attrs)
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
    builder = Nokogiri::XML::Builder.new do
      data {
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
      }
    end
    builder.to_xml
  end

  def update_file
    File.open("#{Rails.root}/data/compta/mapping/#{user.code}.xml",'w') do |f|
      f.write to_xml
    end
  end

  def self.update_files_for(user_codes)
    users = User.any_in(code: user_codes).entries
    grouped_users = users.group_by { |e| e.organization.try(:id) || e.id }
    grouped_users.each do |e|
      users = e[1]
      organization = users.first.organization
      if organization.ibiza && organization.ibiza.is_configured?
        organization.ibiza.update_files_for users
      else
        users.each do |user|
          user.accounting_plan.update_file
        end
      end
    end
    true
  end
end