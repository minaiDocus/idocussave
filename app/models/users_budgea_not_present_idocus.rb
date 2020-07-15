# -*- encoding : UTF-8 -*-
class UsersBudgeaNotPresentIdocus < ApplicationRecord
  scope :has_token, -> { where.not(access_token: nil) }
end