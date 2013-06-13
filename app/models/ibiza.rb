class Ibiza
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :organization

  field :token, type: String
  field :state, type: String, default: 'none'

  field :description,           type: Hash,    default: {}
  field :description_separator, type: Hash,    default: ' - '
  field :is_auto_deliver,       type: Boolean, default: false

  validates_inclusion_of :state, in: %w(none waiting valid invalid)

  before_save :set_state, if: Proc.new { |e| 'token'.in?(e.changed) }

  def is_configured?
    state == 'valid'
  end

  def client
    @_client ||= IbizaAPI::Client.new(self.token)
  end

  def set_state
    if self.token.present?
      self.state = 'waiting'
      verify_token
    else
      self.state = 'none'
    end
  end

  def verify_token
    client.company?
    if client.response.success?
      reload
      self.state = 'valid' if self.token.present?
    else
      reload
      self.state = 'invalid' if self.token.present?
    end
    save unless Rails.env == 'test'
  end
  handle_asynchronously :verify_token, queue: 'ibiza token verification', priority: 0

  def self.update_files_for(user_codes)
    users = User.any_in(code: user_codes).entries
    grouped_users = users.group_by { |e| e.organization.try(:id) || e.id }
    grouped_users.each do |e|
      users = e[1]
      organization = users.first.organization
      if organization.ibiza && organization.ibiza.is_configured?
        organization.ibiza.update_files_for users
      end
    end
    true
  end

  def update_files_for(users)
    client.company?
    if client.response.success?
      if File.exist?("#{Rails.root}/data/compta/mapping/fetch_error.txt")
        `rm #{Rails.root}/data/compta/mapping/fetch_error.txt`
      end
      users.each do |user|
        id = client.response.data.select { |e| e['name'] == user.company }.first.try(:[],:database)
        if id
          client.request.clear
          client.company(id).accounts?
          if client.response.success?
            body = client.response.body
            body.force_encoding('UTF-8')
            if File.exist?("#{Rails.root}/data/compta/mapping/#{user.code}.error")
              `rm #{Rails.root}/data/compta/mapping/#{user.code}.error`
            end
            File.open("#{Rails.root}/data/compta/mapping/#{user.code}.xml",'w') do |f|
              f.write body
            end
          else
            `touch #{Rails.root}/data/compta/mapping/#{user.code}.error`  
          end
        else
          `touch #{Rails.root}/data/compta/mapping/#{user.code}.error`
        end
      end
      true
    else
      `touch #{Rails.root}/data/compta/mapping/fetch_error.txt`
    end
  end

  def export(preseizures)
    client.company?
    if client.response.success?
      result = client.response.data.select { |e| e['name'] == preseizures.first.report.pack.owner.company }.first
      if(id = result.try(:[], 'database'))
        if(e = exercice(id, preseizures.first.report.pack))
          client.request.clear
          data = IbizaAPI::Utils.to_import_xml(e['end'], preseizures, self.description, self.description_separator)
          client.company(id).entries!(data)
          if client.response.success?
            preseizures.each do |preseizure|
              preseizure.update_attribute(:is_delivered, true)
            end
          end
          report = preseizures.first.report
          if report.preseizures.not_delivered.count == 0
            report.update_attribute(:is_delivered, true)
          end
        end
      end
    end
  end

  def exercice(id, pack)
    client.request.clear
    client.company(id).exercices?
    if client.response.success?
      exercices = client.response.data.select do |e|
        e['state'].to_i.in? [0,1]
      end
      part = pack.name.split[2]
      year = part[0..3].to_i
      month = part[4..5]
      case month
      when "1T"
        month = 1
      when "2T"
        month = 4
      when "3T"
        month = 7
      when "4T"
        month = 10
      else
        month = month.to_i
      end
      period = Date.new(year, month, 1)
      exercices.select do |e|
        e['start'].to_date < period && e['end'].to_date > period
      end.first
    else
      raise "[#{pack.name}] No exercice found in #{id}"
    end
  end
end