class Settings
  include Mongoid::AppSettings

  setting :is_subscription_lower_options_disabled, type: Boolean, default: true
  setting :is_journals_modification_authorized,    type: Boolean, default: false

  setting :notify_errors_to,               type: Array,  default: []
  setting :notify_subscription_changes_to, type: Array,  default: []
  setting :notify_ibiza_deliveries_to,     type: Array,  default: []
  setting :notify_on_ibiza_delivery,       type: String, default: 'error' # yes/no/error
end
