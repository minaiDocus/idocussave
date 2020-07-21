# -*- encoding : UTF-8 -*-
class RetrieverBudgeaNotPresentIdocus < ApplicationRecord
  has_many :user, class_name: 'UsersBudgeaNotPresentIdocus'
end