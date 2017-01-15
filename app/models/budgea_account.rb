# -*- encoding : UTF-8 -*-
class BudgeaAccount < ActiveRecord::Base
  belongs_to :user

  # TODO encrypt access_token field

  validates_presence_of :identifier, :access_token
end
