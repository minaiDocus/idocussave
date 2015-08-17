# -*- encoding : UTF-8 -*-
class PrepaCompta::GenerateMapping
  class << self
    def execute
      user_ids = AccountBookType.where(:user_id.exists => true).compta_processable.distinct(:user_id)
      users = User.where(:_id.in => user_ids).active.sort_by(&:code)
      new(users).execute
    end
  end

  def initialize(users)
    @users = users
  end

  def execute
    @users.each do |user|
      write_xml(user.code, user.accounting_plan.to_xml)
    end
    system "zip #{Rails.root.join("data/compta/mapping/mapping.zip")} #{Rails.root.join("data/compta/mapping/*.xml")}"
    csv_data = @users.map do |user|
      user.accounting_plan.to_csv(false)
    end.map(&:presence).compact
    write_csv(csv_data)
    generate_csv_users_list
    true
  end

private

  def write_xml(user_code, content)
    file_path = Rails.root.join("data/compta/mapping/#{user_code}.xml")
    File.write file_path, content
  end

  def write_csv(body)
    header = [['category', 'name', 'number', 'associate', 'customer_code'].join(',')]
    file_path = Rails.root.join("data/compta/abbyy/comptes.csv")
    File.write file_path, (header + body).join("\n")
  end

  def generate_csv_users_list
    lines = [[:code, :name, :company, :address_first_name, :address_last_name, :address_company, :address_1, :address_2, :city, :zip, :state, :country, :country_code].join(',')]
    @users.each do |user|
      address = user.addresses.for_shipping.first
      line = [user.code, user.name, user.company]
      keys = [:first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country]
      keys.each do |key|
        line << address.try(key).try(:gsub, ',', '')
      end
      line << 'FR'
      lines << line.join(',')
    end
    file_path = Rails.root.join('data/compta/abbyy/liste_dossiers.csv')
    File.write file_path, lines.join("\n")
  end
end
