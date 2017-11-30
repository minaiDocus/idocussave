class NotifiableNewPreAssignment < ActiveRecord::Base
  self.table_name = 'notifies_preseizures'

  belongs_to :notify
  belongs_to :preseizure, class_name: 'Pack::Report::Preseizure'
end
