class Notify < ActiveRecord::Base
  belongs_to :user
  has_many :notifiable_document_being_processed, dependent: :destroy
  has_many :temp_document_being_processed, through: :notifiable_document_being_processed, source: :temp_document
  has_many :notifiable_published_documents, dependent: :destroy
  has_many :published_temp_documents, through: :notifiable_published_documents, source: :temp_document
  has_many :notifiable_new_pre_assignments, dependent: :destroy

  TYPES = %w(none now delay).freeze

  validates_inclusion_of :published_docs,   in: TYPES
  validates_inclusion_of :r_new_documents,  in: TYPES
  validates_inclusion_of :r_new_operations, in: TYPES

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
end
