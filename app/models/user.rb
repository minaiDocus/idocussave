class User
  include Mongoid::Document
  include Mongoid::Timestamps
  # Include default devise modules. Others available are:
  # :token_authenticatable, :trackable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable

  before_save :set_prescriber
  before_save :set_clients
  
  attr_accessor :clients_email
  attr_accessor :prescriber_email
         
  field :email
  field :is_admin, :type => Boolean, :default => false
  field :balance_in_cents, :type => Float, :default => 0.0
  field :use_debit_mandate, :type => Boolean, :default => false

  embeds_many :addresses
  
  referenced_in :prescriber, :class_name => 'User', :inverse_of => :clients, :dependent => :nullify
  references_many :clients, :class_name => 'User', :inverse_of => :prescriber, :dependent => :nullify
  
  references_and_referenced_in_many :packs
  
  references_many :prescribed_orders, :class_name => 'Order', :inverse_of => :prescriber, :dependent => :nullify
  
  references_many :orders
  references_many :credits
  references_many :document_tags
  references_one :composition
  references_one :debit_mandate
  references_one :document_content

  def self.find_by_email param
    User.where(:email => param).first
  end
  
  def set_prescriber
    unless prescriber_email.blank?
      if user = User.find_by_email(prescriber_email)
        self.prescriber = user
      end
    else
      self["prescriber_id"] = nil
    end
  end
  
  def set_clients
    rest_of_client_ids = self.clients.collect{|c| c.id}
    unless clients_email.blank?
      clients_email.split(/\s*,\s*/).each do |email|
        user = User.find_by_email(email)
        if user
          rest_of_client_ids -= [user.id]
          unless self.clients.include?(user)
            user.prescriber = self
            user.save
          end
        end
      end
    end
    unless rest_of_client_ids.empty?
      rest_of_client_ids.each do |client_id|
        user = User.find(client_id)
        user["prescriber_id"] = nil
        user.save
      end
    end
  end
  
  def get_clients_email
    if self.clients
      emails = ""
      self.clients.each_with_index do |client,index|
        if index != 0
          emails += ", #{client.email}"
        else
          emails += "#{client.email}"
        end
      end
      emails
    end
  end
  
end
