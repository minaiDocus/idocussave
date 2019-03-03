# -*- encoding : UTF-8 -*-
class FileNamingPolicy < ApplicationRecord
  belongs_to :organization


  validates_inclusion_of :scope,     in: %w(organization collaborators)
  validates_inclusion_of :separator, in: ['-', '_']
  validates_inclusion_of :first_user_identifier, in: %w(code company)
  validates_inclusion_of :second_user_identifier, in: %w(code company), if: -> (p) { p.second_user_identifier.present? }


  with_options in: 0..10 do |policy|
    policy.validates_inclusion_of :period_position
    policy.validates_inclusion_of :journal_position
    policy.validates_inclusion_of :third_party_position
    policy.validates_inclusion_of :piece_number_position
    policy.validates_inclusion_of :invoice_date_position
    policy.validates_inclusion_of :invoice_number_position
    policy.validates_inclusion_of :first_user_identifier_position
    policy.validates_inclusion_of :second_user_identifier_position
  end


  def pre_assignment_needed?
    is_third_party_used || is_invoice_number_used || is_invoice_date_used
  end
end
