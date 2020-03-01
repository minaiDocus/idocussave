# -*- encoding : UTF-8 -*-
class SandboxOperation < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :user, optional: true
  belongs_to :sandbox_bank_account, optional: true

  validates_presence_of :date, :label, :amount
end
