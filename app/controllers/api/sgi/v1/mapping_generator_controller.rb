# frozen_string_literal: true

class Api::Sgi::V1::MappingGeneratorController < SgiApiController

  # GET /api/sgi/v1/mapping_generator/get_xml
  def get_xml
    render xml: generate_xml_data, status: 200, content_type: 'application/xml'
  end

  # GET /api/sgi/v1/mapping_generator/get_csv
  def get_csv
    render plain: generate_csv_data, status: 200, content_type: 'application/csv'
  end

  # GET /api/sgi/v1/mapping_generator/get_csv_users_list
  def get_csv_users_list
    render plain: generate_csv_users_list, status: 200, content_type: 'application/csv'
  end

  private

  def user
    account_book_type = AccountBookType.find_by_user_id(params[:user_id])
    _user = User.find(account_book_type.user_id) if account_book_type && account_book_type.entry_type > 0
    return _user if _user.active?
  end

  def generate_xml_data
    user.accounting_plan.to_xml if user.accounting_plan
  end

  def generate_csv_data
    user.accounting_plan.to_csv(true) if user.accounting_plan
  end

  def generate_csv_users_list
    lines = [[:code, :name, :company, :address_first_name, :address_last_name, :address_company, :address_1, :address_2, :city, :zip, :state, :country, :country_code].join(',')]

    user_ids = AccountBookType.where('user_id IS NOT NULL').compta_processable.pluck(:user_id)
    users = User.where(id: user_ids).active.sort_by(&:code)
    
    users.each do |_user|
      address = _user.paper_return_address

      line = [_user.code, _user.name, _user.company]
      keys = [:first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country]

      keys.each do |key|
        line << address.try(key).try(:gsub, ',', '')
      end

      line << 'FR'
      lines << line.join(',')
    end

    lines.join("\n")
  end

end