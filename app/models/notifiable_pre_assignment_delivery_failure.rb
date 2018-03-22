class NotifiablePreAssignmentDeliveryFailure < ActiveRecord::Base
  self.table_name = 'notifies_pre_assignment_deliveries'

  belongs_to :notify
  belongs_to :pre_assignment_delivery
end
