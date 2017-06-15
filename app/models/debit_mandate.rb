# -*- encoding : UTF-8 -*-
class DebitMandate < ActiveRecord::Base
  # TODO: remove user references after migration
  belongs_to :user
  belongs_to :organization

  scope :configured,     -> { where(transactionStatus: 'success') }
  scope :not_configured, -> { where.not(transactionStatus: ['success']) }

  after_create :set_client_reference

  validates_presence_of :clientReference, if: proc { |dm| dm.persisted? }

  def pending?
    transactionStatus.nil?
  end

  def configured?
    transactionStatus == 'success'
  end

private

  def set_client_reference
    update_attribute(:clientReference, "#{'%0.5d' % id}#{organization.code}")
  end
end
