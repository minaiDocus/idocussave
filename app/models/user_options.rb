class UserOptions < ActiveRecord::Base
  belongs_to :user


  validates_inclusion_of :is_auto_deliver,                 in: [-1, 0, 1]
  validates_inclusion_of :is_pre_assignment_date_computed, in: [-1, 0, 1]


  def pre_assignment_date_computed?
    if is_pre_assignment_date_computed == -1
      user.organization.try(:is_pre_assignment_date_computed)
    else
      is_pre_assignment_date_computed == 1
    end
  end

  # -1 means we refer to organization
  # 0 means manuel deliver
  # 1 means auto deliver
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


  def upload_authorized?
    is_upload_authorized
  end
end
