# -*- encoding : UTF-8 -*-
class SandboxOperation < ActiveRecord::Base
  belongs_to :organization
  belongs_to :user
  belongs_to :sandbox_bank_account

  validates_presence_of :date, :label, :amount
end
