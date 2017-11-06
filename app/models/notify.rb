class Notify < ActiveRecord::Base
  belongs_to :user

  TYPES = %w(none now delay).freeze

  validates_inclusion_of :r_new_documents,  in: TYPES
  validates_inclusion_of :r_new_operations, in: TYPES

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
