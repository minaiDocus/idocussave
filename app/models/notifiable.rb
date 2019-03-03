class Notifiable < ApplicationRecord
  self.table_name = 'notifiables_notifies'

  belongs_to :notifiable, polymorphic: true
  belongs_to :notify

  scope :pre_assignment_delivery_failures, -> { where(notifiable_type: 'PreAssignmentDelivery',    label: 'failure') }
  scope :new_pre_assignments,              -> { where(notifiable_type: 'Pack::Report::Preseizure', label: 'new') }
  scope :published_documents,              -> { where(notifiable_type: 'TempDocument',             label: 'published') }
  scope :document_being_processed,         -> { where(notifiable_type: 'TempDocument',             label: 'processing') }
end
