# -*- encoding : UTF-8 -*-
class FileNamingPolicy
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization

  field :scope,                           type: String,  default: 'organization'
  field :separator,                       type: String,  default: '_'
  field :first_user_identifier,           type: String,  default: 'code'
  field :first_user_identifier_position,  type: Integer, default: 1
  field :second_user_identifier,          type: String,  default: ''
  field :second_user_identifier_position, type: Integer, default: 1
  field :is_journal_used,                 type: Boolean, default: true
  field :journal_position,                type: Integer, default: 2
  field :is_period_used,                  type: Boolean, default: true
  field :period_position,                 type: Integer, default: 3
  field :is_piece_number_used,            type: Boolean, default: true
  field :piece_number_position,           type: Integer, default: 4
  field :is_third_party_used,             type: Boolean, default: false
  field :third_party_position,            type: Integer, default: 5
  field :is_invoice_number_used,          type: Boolean, default: false
  field :invoice_number_position,         type: Integer, default: 6
  field :is_invoice_date_used,            type: Boolean, default: false
  field :invoice_date_position,           type: Integer, default: 7

  validates_inclusion_of :scope, in: %w(organization collaborators)
  validates_inclusion_of :separator, in: ['-', '_']
  validates_inclusion_of :first_user_identifier, in: %w(code company)
  validates_inclusion_of :second_user_identifier, in: %w(code company), if: -> p { p.second_user_identifier.present? }

  def pre_assignment_needed?
    is_third_party_used || is_invoice_number_used || is_invoice_date_used
  end
end
