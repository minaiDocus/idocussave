# -*- encoding : UTF-8 -*-
class DebitMandate
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :transactionId
  field :transactionStatus
  field :transactionErrorCode
  field :signatureOperationResult
  field :signatureDate
  field :mandateScore
  field :clientReference
  field :cardTransactionId
  field :cardRequestId
  field :cardOperationType
  field :cardOperationResult
  field :collectOperationResult
  field :invoiceReference
  field :invoiceAmount
  field :invoiceExecutionDate
  field :reference
  field :title
  field :firstName
  field :lastName
  field :email
  field :bic
  field :iban
  field :RUM
  field :companyName
  field :organizationId
  field :invoiceLine1
  field :invoiceLine2
  field :invoiceCity
  field :invoiceCountry
  field :invoicePostalCode
  field :deliveryLine1
  field :deliveryLine2
  field :deliveryCity
  field :deliveryCountry
  field :deliveryPostalCode

  scope :configured,     -> { where(transactionStatus: 'success') }
  scope :not_configured, -> { where(:transactionStatus.nin => ['success']) }

  def is_configured?
    transactionStatus == 'success'
  end
end
