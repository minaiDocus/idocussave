class Settings
  include Mongoid::AppSettings

  setting :is_journals_modification_authorized, type: Boolean, default: false

  setting :notify_errors_to,               type: Array,  default: []
  setting :notify_subscription_changes_to, type: Array,  default: []
  setting :notify_ibiza_deliveries_to,     type: Array,  default: []
  setting :notify_on_ibiza_delivery,       type: String, default: 'error' # yes/no/error
  setting :notify_scans_not_delivered_to,  type: Array,  default: []

  setting :dropbox_extended_session

  # operator : { username: '', password: '', scanning_provider: '', is_return_labels_authorized: false }
  setting :paper_process_operators, type: Array, default: []
end
