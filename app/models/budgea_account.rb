# -*- encoding : UTF-8 -*-
class BudgeaAccount
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Locker

  belongs_to :user

  field :identifier
  # TODO encrypt me
  field :access_token

  validates_presence_of :identifier, :access_token
end
