class AccountNumberRule < ApplicationRecord
  belongs_to              :organization, optional: true
  has_and_belongs_to_many :users


  validate :uniqueness_of_name
  validates_presence_of  :name, :rule_type, :affect, :content, :priority, :rule_target
  validates_presence_of  :third_party_account, if: Proc.new { |r| r.rule_type == 'match' }
  validates_inclusion_of :rule_type, in: %w(truncate match)
  validates_inclusion_of :affect, in: %w(organization user)
  validates_inclusion_of :rule_target, in: %w(debit credit both)


  scope :credit,    -> { where(rule_target: 'credit') }
  scope :debit,    -> { where(rule_target: 'debit') }
  scope :global,    -> { where(affect: 'organization') }
  scope :customers, -> { where(affect: 'user') }


  def name_pattern
    name.gsub(/\s+\(\d+\)\z/, '')
  end


  def similar_name
    organization.account_number_rules.where("name like ?", "%#{name_pattern}%")
  end


  def rule_type_short_name
    case rule_type
      when 'match'    then 'recherche'
      when 'truncate' then 'correction'
      else nil
    end
  end


  def self.import(file, account_number_rule_params, organization)
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

        attrs = {
          name: encoded_hash['NOM'],
          rule_type: encoded_hash['TYPE'],
          content: encoded_hash['CONTENU_RECHERCHE'],
          third_party_account: encoded_hash['NUMERO_COMPTE'],
          priority: encoded_hash['PRIORITE'],
          categorization: encoded_hash['CATEGORISATION']
        }

        attrs[:rule_type] = case attrs[:rule_type].to_s
           when /recherche/i  then 'match'
           when /correction/i then 'truncate'
           else nil
        end

        attrs[:affect]              = account_number_rule_params[:affect]
        attrs[:user_ids]            = account_number_rule_params[:user_ids] if account_number_rule_params[:affect] == 'user'
        attrs[:third_party_account] = nil if attrs[:rule_type] == 'truncate'

        attrs[:rule_target] = if encoded_hash['CIBLE'].try(:downcase).to_s == 'credit'
                                'credit'
                              elsif encoded_hash['CIBLE'].try(:downcase).to_s == 'debit'
                                'debit'
                              else
                                'both'
                              end

        template     = organization.account_number_rules.where(name: attrs[:name]).first
        attrs[:name] = template.name_pattern + " (#{template.similar_name.size + 1})" if template

        organization.account_number_rules.create(attrs)
      end

      true
    rescue => e
      false
    end
  end


  def self.search_for_collection(collection, contains)
    return collection if collection.empty?
    organization = collection.first.organization

    collection = collection.where("name LIKE ?", "%#{contains[:name]}%") if contains[:name].present?
    collection = collection.where(affect:    contains[:affect])      if contains[:affect].present?
    collection = collection.where(rule_type: contains[:rule_type])   if contains[:rule_type].present?
    collection = collection.where(rule_target: contains[:rule_target])   if contains[:rule_target].present?
    collection = collection.where("content LIKE ?", "%#{contains[:content]}%") if contains[:content].present?
    collection = collection.where("categorization LIKE ?", "%#{contains[:categorization]}%")           if contains[:categorization].present?
    collection = collection.where("third_party_account LIKE ?", "%#{contains[:third_party_account]}%") if contains[:third_party_account].present?


    if contains[:affect] != 'organization' && contains[:customer_code].present?
      user_ids = organization.customers.where("code LIKE ?", "%#{contains[:customer_code]}%").pluck(:id)

      collection = collection.joins(:users).where('users.id IN (?)', user_ids)
    end

    collection
  end


private

  def uniqueness_of_name
    rule = organization.account_number_rules.where(name: name).first
    errors.add(:name, :taken) if rule && rule != self
  end
end
