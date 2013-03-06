class Ibiza
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization

  field :token, type: String
  field :state, type: String, default: 'none'

  validates_inclusion_of :state, in: %w(none waiting valid invalid)

  attr_accessible :token

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
    response = client.company
    if response.is_a?(OpenStruct) && response.result == 'Success'
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
    grouped_users = users.group_by { |e| e.prescriber.try(:id) || e.id }
    grouped_users.each do |e|
      users = e[1]
      prescriber = users.first.prescriber || users.first
      if prescriber.ibiza && prescriber.ibiza.is_configured?
        prescriber.ibiza.update_files_for users
      end
    end
    true
  end

  def update_files_for(users)
    response = client.company
    if response.is_a?(OpenStruct) && response.result == 'Success'
      if File.exist?("#{Rails.root}/data/compta/mapping/fetch_error.txt")
        `rm #{Rails.root}/data/compta/mapping/fetch_error.txt`
      end
      users.each do |user|
        id = response.company.select { |e| e[:name] == user.company }.first.try(:[],:id)
        if id
          body = client.raw_accounts(id)
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
      end
      true
    else
      `touch #{Rails.root}/data/compta/mapping/fetch_error.txt`
    end
  end
end