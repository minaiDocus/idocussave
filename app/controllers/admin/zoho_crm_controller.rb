# encoding: utf-8
class Admin::ZohoCrmController < Admin::AdminController
  def index
  end

  def synchronize
    # @report = ZohoControl.new.execute
    @report = []
    render text: "Dont launch synchro here anymore, launch it from console"
  end

  def duplicate_organizations
    options = {
                duplication_key: 'Account Name',
                search_column:   'Code iDocus',
                id_data:         'ACCOUNTID'
              }
    @duplicate_datas = search_duplicate(ZohoControl.new.get_datas('Accounts'), options)
    @title = 'Doublon organisations'

    render 'duplicate'
  end

  def duplicate_users
    options = {
                duplication_key: 'Code iDocus',
                search_column:   'Email',
                id_data:         'CONTACTID'
              }
    @duplicate_datas = search_duplicate(ZohoControl.new.get_datas('Contacts'), options)
    @title = 'Doublon Contacts'

    render 'duplicate'
  end

  private

  def search_duplicate(datas, options={})
    duplicate = {}
    memo = {}
    duplication_key = options[:duplication_key]
    search_column   = options[:search_column]
    id_data         = options[:id_data]

    datas.each do |data|
      key_d = nil
      key_d = data[duplication_key].downcase.to_s if data[duplication_key].present?
      if memo[key_d].present?
        duplicate[key_d] = memo[key_d] unless duplicate[key_d].present?
        duplicate[key_d] << [data[search_column], data[id_data]]
      end
      memo[key_d] = [[data[search_column], data[id_data]]]
    end
    return duplicate
  end

end
