# -*- encoding : UTF-8 -*-
class RetrieversBudgeaNotPresentIdocus < ApplicationRecord
  has_many :user, class_name: 'UsersBudgeaNotPresentIdocus'
end