class AccountNumberRule
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Slug

  belongs_to              :organization
  has_and_belongs_to_many :users

  field :name
  field :rule_type
  field :affect
  field :content
  field :third_party_account
  field :priority,            type: Integer, default: 0
  field :categorization

  slug :name

  index({ name: 1 })
  index({ categorization: 1 })
  index({ rule_type: 1 })

  validates_presence_of :name, :rule_type, :affect, :content, :priority
  validates_presence_of :third_party_account, if: Proc.new { |r| r.rule_type == 'match' }
  validates_inclusion_of :rule_type, in: %w(truncate match)
  validates_inclusion_of :affect, in: %w(organization user)
  validate :uniqueness_of_name

  scope :global,    -> { where(affect: 'organization') }
  scope :customers, -> { where(affect: 'user') }

  def name_pattern
    name.gsub(/\s+\(\d+\)\z/, '')
  end

  def similar_name
    organization.account_number_rules.where(name: /#{name_pattern}/)
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
      ::CSV.foreach(file.path, headers: true, col_sep: ';') do |row|
        attrs = row.to_hash.slice('PRIORITE','NOM','TYPE','CATEGORISATION','CONTENU_RECHERCHE','NUMERO_COMPTE')
        attrs = { 
          name: attrs['NOM'],
          rule_type: attrs['TYPE'],
          content: attrs['CONTENU_RECHERCHE'],
          third_party_account: attrs['NUMERO_COMPTE'],
          priority: attrs['PRIORITE'],
          categorization: attrs['CATEGORISATION']
        }
        attrs[:rule_type] = case attrs[:rule_type].to_s 
           when /recherche/i  then 'match'
           when /correction/i then 'truncate'
           else nil
        end 
        attrs[:third_party_account] = nil if attrs[:rule_type] == 'truncate'
        attrs[:affect]              = account_number_rule_params[:affect]
        attrs[:user_ids]            = account_number_rule_params[:user_ids] if account_number_rule_params[:affect] == 'user'
        template = organization.account_number_rules.where(name: /#{attrs[:name]}/).first
        attrs[:name] = template.name_pattern + " (#{template.similar_name.size + 1})" if template
        organization.account_number_rules.create(attrs)
      end
      true
    rescue
      false
    end
  end

private

  def uniqueness_of_name
    rule = organization.account_number_rules.where(name: name).first
    errors.add(:name, :taken) if rule && rule != self
  end
end
