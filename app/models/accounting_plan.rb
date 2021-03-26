# -*- encoding : UTF-8 -*-
class AccountingPlan < ApplicationRecord
  # IBIZA     = 'ibiza'.freeze
  # COALA     = 'coala'.freeze
  # QUADRATUS = 'quadratus'.freeze

  has_many :providers, -> { where(kind: 'provider') }, class_name: 'AccountingPlanItem', as: :accounting_plan_itemable, dependent: :destroy
  has_many :customers, -> { where(kind: 'customer') }, class_name: 'AccountingPlanItem', as: :accounting_plan_itemable, dependent: :destroy
  has_many :vat_accounts, class_name: 'AccountingPlanVatAccount', inverse_of: :accounting_plan

  belongs_to :user

  accepts_nested_attributes_for :providers,    allow_destroy: true
  accepts_nested_attributes_for :customers,    allow_destroy: true
  accepts_nested_attributes_for :vat_accounts, allow_destroy: true

  scope :updating,     -> { where(is_updating: true) }

  def import(file, type)
    items = type == 'providers' ? providers : customers
    begin
      csv_string = File.read(file.path)
      csv_string.encode!('UTF-8')

      begin
        csv_string.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '') if csv_string.match(/\\x([0-9a-zA-Z]{2})/)
      rescue => e
        csv_string.force_encoding('ISO-8859-1').encode!('UTF-8', undef: :replace, invalid: :replace, replace: '')
      end

      csv_string.gsub!("\xEF\xBB\xBF".force_encoding("UTF-8"), '') #deletion of UTF-8 BOM

      ::CSV.parse(csv_string, headers: true, col_sep: ';') do |row|
        encoded_hash = row.to_hash.with_indifferent_access

        attrs = { third_party_name: encoded_hash['NOM_TIERS'], third_party_account: encoded_hash['COMPTE_TIERS'], conterpart_account: encoded_hash['COMPTE_CONTREPARTIE'], code: encoded_hash['CODE_TVA'] }

        if (item = items.find_by_name(encoded_hash['NOM_TIERS']))
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
    rescue => e
      false
    end
  end

  def create_json_format
    _address = user.paper_return_address

    { 'address': {
        'name':         user.company,
        'contact':      user.name,
        'address_1':    _address.try(:address_1),
        'address_2':    _address.try(:address_2),
        'zip':          _address.try(:zip),
        'city':         _address.try(:city),
        'country':      _address.try(:country),
        'country_code': 'FR'
      },

      'accounting_plans': {
        'ws_accounts': extract_data_of(active_customers, 1) + extract_data_of(active_providers, 2)
      }
    }
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
          active_customers.each do |customer|
            wsAccounts do
              category 1
              associate customer.conterpart_account
              name customer.third_party_name
              number customer.third_party_account
              send(:'vat-account', vat_accounts.find_by_code(customer.code).try(:account_number))
            end
          end

          active_providers.each do |provider|
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

    [[1, active_customers], [2, active_providers]].each do |category, accounts|
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

  def cleanNotUpdatedItems
    # TO DO : temp fix, keep not updated datas
    # self.providers.where(is_updated: false).each(&:destroy)
    # self.customers.where(is_updated: false).each(&:destroy)
  end

  def need_update?
    return false if (user.uses?(:ibiza) && !user.ibiza.try(:auto_update_accounting_plan?)) || (user.uses?(:my_unisoft) && !user.my_unisoft.try(:is_auto_updating_accounting_plan))

    return true unless last_checked_at
    last_checked_at < 4.hours.ago && !is_updating
  end

  def active_customers
    customers.where(is_updated: true)
  end

  def active_providers
    providers.where(is_updated: true)
  end

  private

  def extract_data_of(objects, category)
    data_content = []
    objects.each do |object|
      content = {
        'category':    category,
        'associate':   object.conterpart_account,
        'name':        object.third_party_name,
        'number':      object.third_party_account,
        'vat_account': vat_accounts.any? ? (vat_accounts.find_by_code(object.code).try(:account_number)).presence : object.code.presence
      }

      data_content << content

    end
    data_content
  end
end
