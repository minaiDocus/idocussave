class User
  include Mongoid::Document
  include Mongoid::Timestamps
  # Include default devise modules. Others available are:
  # :token_authenticatable, :trackable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :validatable
         
  field :email
  field :is_admin, :type => Boolean, :default => false
  field :balance_in_cents, :type => Float, :default => 0.0
  field :use_debit_mandate, :type => Boolean, :default => false
  field :code, :type => String
  field :first_name, :type => String
  field :last_name, :type => String
  field :company, :type => String

  embeds_many :addresses
  
  referenced_in :reporting
  
  references_and_referenced_in_many :packs
  
  references_many :orders
  references_many :credits
  references_many :document_tags
  references_many :events
  references_many :subscriptions
  references_one :composition
  references_one :debit_mandate
  references_one :delivery

  def self.find_by_email param
    User.where(:email => param).first
  end
  
  def self.find_by_emails params
    User.any_in(:email => params).entries
  end
  
  def is_subscribed_to_category number
    if self.subscriptions.where(:category => number).first
      true
    else
      false
    end
  end
end
