class OrganizationRights
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :user

  field :is_groups_management_authorized,    type: Boolean, default: true
  field :is_customers_management_authorized, type: Boolean, default: true
  field :is_journals_management_authorized,  type: Boolean, default: true
end