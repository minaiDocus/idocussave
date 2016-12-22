# -*- encoding : UTF-8 -*-
class DebitMandate < ActiveRecord::Base
  belongs_to :user


  scope :configured,     -> { where(transactionStatus: 'success') }
  scope :not_configured, -> { where.not(transactionStatus: ['success']) }


  def is_configured?
    transactionStatus == 'success'
  end
end
