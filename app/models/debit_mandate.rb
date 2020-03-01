# -*- encoding : UTF-8 -*-
class DebitMandate < ApplicationRecord
  audited

  belongs_to :organization

  scope :configured,     -> { where(transactionStatus: 'success') }
  scope :not_configured, -> { where("transactionStatus IS NULL OR transactionStatus != 'success'") }

  after_create :set_client_reference

  validates_presence_of :clientReference, if: proc { |dm| dm.persisted? }

  def pending?
    !transactionStatus.present?
  end

  def started?
    transactionStatus == 'started'
  end

  def configured?
    transactionStatus == 'success'
  end

private

  def set_client_reference
    update_attribute(:clientReference, "#{'%0.5d' % id}#{organization.code}") if clientReference.blank?
  end
end
