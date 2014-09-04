# -*- encoding : UTF-8 -*-
class Ibiza
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :organization

  field :token, type: String
  field :state, type: String, default: 'none'

  field :description,           type: Hash,    default: {}
  field :description_separator, type: String,  default: ' - '
  field :piece_name_format,     type: Hash,    default: {}
  field :piece_name_format_sep, type: String,  default: ' '
  field :is_auto_deliver,       type: Boolean, default: false

  validates_inclusion_of :state, in: %w(none waiting valid invalid)

  before_save :set_state, if: Proc.new { |e| 'token'.in?(e.changed) }
  after_update :flush_users_cache, if: Proc.new { |e| 'token'.in?(e.changed) }

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
    users.each do |user|
      if user.ibiza_id
        client.request.clear
        client.company(user.ibiza_id).accounts?
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
  end

  # nil : updating cache
  # [...] : cached values
  # false : error occurs
  def users
    result = Rails.cache.read([:ibiza, id, :users])
    get_users_only_once if result.nil?
    result
  end

  def get_users_only_once
    unless Rails.cache.read([:ibiza, id, :users_is_flushing])
      get_users
      Rails.cache.write([:ibiza, id, :users_is_flushing], true)
    end
  end

  def get_users
    client.request.clear
    client.company?
    result = nil
    if client.response.success?
      result = client.response.data.map do |e|
        o = OpenStruct.new
        o.name = e['name']
        o.id = e['database']
        o
      end
    else
      result = false
    end
    Rails.cache.write([:ibiza, id, :users_is_flushing], false)
    Rails.cache.write([:ibiza, id, :users], result)
    result
  end
  handle_asynchronously :get_users, queue: 'ibiza get users', priority: 1

  def flush_users_cache
    Rails.cache.delete([:ibiza, id, :users])
  end

  def auto_assign_users
    get_users_without_delay
    if users
      organization.customers.each do |customer|
        if (e = users.select { |e| e.name == customer.company }.first)
          customer.update_attribute(:ibiza_id, e.id)
        end
      end
    end
  end

  def export(preseizures)
    if preseizures.any?
      data = nil
      ids = preseizures.map(&:id)
      is_delivered_one_by_one = false
      report = preseizures.first.report
      if(id = report.user.ibiza_id)
        period = DocumentTools.to_period(report.name)
        if (exercice=ExerciceService.find(report.user, period, false))
          client.request.clear
          data = IbizaAPI::Utils.to_import_xml(exercice, preseizures, self.description, self.description_separator, self.piece_name_format, self.piece_name_format_sep)
          client.company(id).entries!(data)
          if client.response.success?
            Pack::Report::Preseizure.where(:_id.in => ids).update_all(is_delivered: true)
            report.delivery_message = ''
          else
            IbizaMailer.notify_delivery(self, report, data).deliver if IbizaAPI::Config::NOTIFY_ON_DELIVERY == :error
            is_delivered_one_by_one = true
            report.delivery_message = client.response.message
            preseizures.each do |preseizure|
              client.request.clear
              data2 = IbizaAPI::Utils.to_import_xml(exercice, [preseizure], self.description, self.description_separator, self.piece_name_format, self.piece_name_format_sep)
              client.company(id).entries!(data2)
              if client.response.success?
                preseizure.update_attributes(delivery_message: '', is_delivered: true)
              else
                preseizure.update_attribute(:delivery_message, client.response.message)
                IbizaMailer.notify_delivery(self, preseizure, data2).deliver if IbizaAPI::Config::NOTIFY_ON_DELIVERY == :error
              end
              IbizaMailer.notify_delivery(self, preseizure, data2).deliver if IbizaAPI::Config::NOTIFY_ON_DELIVERY == :yes
              preseizure.update_attributes(is_locked: false, delivery_tried_at: Time.now)
            end
          end
          IbizaMailer.notify_delivery(self, report, data).deliver if IbizaAPI::Config::NOTIFY_ON_DELIVERY == :yes
          if report.preseizures.not_delivered.count == 0
            report.update_attribute(:is_delivered, true)
          end
        else
          if client.response.success?
            report.delivery_message = "L'exercice correspondant n'est pas défini dans Ibiza."
          else
            report.delivery_message = client.response.message
            IbizaMailer.notify_delivery(self, report, data).deliver if IbizaAPI::Config::NOTIFY_ON_DELIVERY == :error
          end
        end
      else
        report.delivery_message = "L'utilisateur #{report.user.code} n'a pas de compte Ibiza lié."
      end
      unless is_delivered_one_by_one
        Pack::Report::Preseizure.where(:_id.in => ids).update_all(is_locked: false, delivery_tried_at: Time.now, delivery_message: report.delivery_message)
      end
      report.delivery_tried_at = Time.now
      report.is_locked = false
      report.save
      report.delivery_message
    end
  end

  def exercices(id)
    Rails.cache.fetch "ibiza_#{id}_exercices", expires_in: 1.hour do
      client.request.clear
      client.company(id).exercices?
      if client.response.success?
        client.response.data
      else
        raise NoExercicesFound, "for #{id}"
      end
    end
  end

  class NoExercicesFound < RuntimeError; end
end
