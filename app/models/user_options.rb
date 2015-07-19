class UserOptions
  include Mongoid::Document
  include Mongoid::Timestamps

  belongs_to :user

  field :max_number_of_journals,          type: Integer, default: 5
  field :is_preassignment_authorized,     type: Boolean, default: false
  field :is_taxable,                      type: Boolean, default: true
  field :is_pre_assignment_date_computed, type: Integer, default: -1
  field :is_auto_deliver,                 type: Integer, default: -1
  field :is_own_csv_descriptor_used,      type: Boolean, default: false

  validates_inclusion_of :is_pre_assignment_date_computed, in: [-1, 0, 1]
  validates_inclusion_of :is_auto_deliver,                 in: [-1, 0, 1]

  def pre_assignment_date_computed?
    if is_pre_assignment_date_computed == -1
      user.organization.try(:is_pre_assignment_date_computed)
    else
      is_pre_assignment_date_computed == 1
    end
  end

  def auto_deliver?
    if is_auto_deliver == -1
      user.organization.try(:ibiza).try(:is_auto_deliver)
    else
      is_auto_deliver == 1
    end
  end

  def own_csv_descriptor_used?
    is_own_csv_descriptor_used
  end
end
