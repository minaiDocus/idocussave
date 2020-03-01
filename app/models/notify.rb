class Notify < ApplicationRecord
  belongs_to :user
  has_many :notifiables, dependent: :destroy
  has_many :notifiable_document_being_processed,         -> { document_being_processed },         class_name: 'Notifiable'
  has_many :notifiable_published_documents,              -> { published_documents },              class_name: 'Notifiable'
  has_many :notifiable_new_pre_assignments,              -> { new_pre_assignments },              class_name: 'Notifiable'
  has_many :notifiable_pre_assignment_delivery_failures, -> { pre_assignment_delivery_failures }, class_name: 'Notifiable'
  has_many :pre_assignment_delivery_failures, through: :notifiables, source: :notifiable, source_type: 'PreAssignmentDelivery'

  TYPES = %w(none now delay).freeze

  validates_inclusion_of :published_docs,                 in: TYPES
  validates_inclusion_of :r_new_documents,                in: TYPES
  validates_inclusion_of :r_new_operations,               in: TYPES
  validates_inclusion_of :pre_assignment_delivery_errors, in: TYPES

  def published_docs?
    published_docs != 'none'
  end

  def published_docs_now?
    published_docs == 'now'
  end

  def published_docs_delayed?
    published_docs == 'delay'
  end

  def r_new_documents_now?
    r_new_documents == 'now'
  end

  def r_new_documents_delayed?
    r_new_documents == 'delay'
  end

  def r_new_operations_now?
    r_new_operations == 'now'
  end

  def r_new_operations_delayed?
    r_new_operations == 'delay'
  end

  def pre_assignment_delivery_errors?
    pre_assignment_delivery_errors != 'none'
  end

  def pre_assignment_delivery_errors_now?
    pre_assignment_delivery_errors == 'now'
  end

  def pre_assignment_delivery_errors_delayed?
    pre_assignment_delivery_errors == 'delay'
  end
end
