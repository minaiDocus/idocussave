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

  embeds_many :addresses
  
  references_and_referenced_in_many :packs
  
  references_many :orders
  references_many :credits
  references_many :document_tags
  references_one :composition

  def self.find_by_email param
    User.where(:email => param).first
  end
end
