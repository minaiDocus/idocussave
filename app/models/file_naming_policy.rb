class FileNamingPolicy
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :organization

  field :is_active,                       type: Boolean, default: false
  field :separator,                       type: String,  default: '_'
  field :first_user_identifier,           type: String,  default: 'Code client iDocus'
  field :first_user_identifier_position,  type: Integer, default: 1
  field :second_user_identifier
  field :second_user_identifier_position, type: Integer
  field :is_journal_used,                 type: String,  default: "Oui"
  field :journal_position,                type: Integer, default: 2
  field :is_period_used,                  type: String,  default: "Oui"
  field :period_position,                 type: Integer, default: 3
  field :is_piece_number_used,                   type: String,  default: "Oui"
  field :piece_number_position,                  type: Integer, default: 4
  field :is_third_party_used,             type: String,  default: "Non"
  field :third_party_position,            type: Integer
  field :is_invoice_number_used,          type: String,  default: "Non"
  field :invoice_number_position,         type: Integer
  field :is_invoice_date_used,            type: String,  default: "Non"
  field :invoice_date_position,           type: Integer
end
