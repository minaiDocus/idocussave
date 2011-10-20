class SuperUser
  include Mongoid::Document
  include Mongoid::Timestamps
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable, :trackable, :lockable and :timeoutable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  field :email

  def self.find_by_email param
    SuperUser.where(:email => param).first
  end
end
