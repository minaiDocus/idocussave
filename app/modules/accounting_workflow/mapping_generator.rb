class AccountingWorkflow::MappingGenerator
  def self.execute
    user_ids = AccountBookType.where('user_id IS NOT NULL').compta_processable.pluck(:user_id)
    users = User.where(id: user_ids).active.sort_by(&:code)
    new(users).execute
  end


  def initialize(users)
    @users = users
  end


  def execute
    @users.each do |user|
      write_xml(user.code, user.accounting_plan.to_xml) if user.accounting_plan
    end

    system "zip -j #{dir.join('mapping.zip')} #{dir.join('*.xml')}"

    csv_data = @users.map do |user|
      user.accounting_plan.to_csv(false) if user.accounting_plan
    end.map(&:presence).compact

    write_csv(csv_data)

    generate_csv_users_list
    true
  end

  private


  def dir
    AccountingWorkflow.pre_assignments_dir.join('mapping')
  end


  def abbyy_dir
    AccountingWorkflow.pre_assignments_dir.join('abbyy')
  end


  def write_xml(user_code, content)
    file_path = dir.join("#{user_code}.xml")
    File.write file_path, content
  end


  def write_csv(body)
    header = [%w(category name number associate customer_code).join(',')]
    file_path = abbyy_dir.join('comptes.csv')
    File.write file_path, (header + body).join("\n")
  end


  def generate_csv_users_list
    lines = [[:code, :name, :company, :address_first_name, :address_last_name, :address_company, :address_1, :address_2, :city, :zip, :state, :country, :country_code].join(',')]

    @users.each do |user|
      address = user.paper_return_address

      line = [user.code, user.name, user.company]
      keys = [:first_name, :last_name, :company, :address_1, :address_2, :city, :zip, :state, :country]

      keys.each do |key|
        line << address.try(key).try(:gsub, ',', '')
      end

      line << 'FR'
      lines << line.join(',')
    end

    file_path = abbyy_dir.join('liste_dossiers.csv')

    File.write file_path, lines.join("\n")
  end
end
