### Migrate data for membership system

# Create a membership for each collaborator
# TODO : create membership to all 3 organizations for Extentis
# TODO : remove code from collaborator
# TODO : empty organization_id for collaborator
User.prescribers.each do |u|
  m = Member.find_by user_id: u.id, organization_id: u.organization_id
  next if m

  if u.organization.leader_id == u.id
    role = Member::ADMIN
  else
    role = Member::COLLABORATOR
  end

  Member.create(
    user_id: u.id,
    organization_id: u.organization_id,
    role: role,
    code: u.code,
    created_at: u.created_at,
    manage_groups: u.organization_rights_is_groups_management_authorized,
    manage_collaborators: u.organization_rights_is_collaborators_management_authorized,
    manage_customers: u.organization_rights_is_customers_management_authorized,
    manage_journals: u.organization_rights_is_journals_management_authorized,
    manage_customer_journals: u.organization_rights_is_customer_journals_management_authorized
  )

  print '.'
end; nil

# Reassign group membership from collaborator to member
Group.all.each do |g|
  g.users.prescribers.each do |u|
    m = Member.find_by user_id: u.id, organization_id: g.organization_id
    next if m.groups.include?(g)
    m.groups << g
    m.save
    print '.'
  end
end; nil

# Migrate parent/child relationship
User.customers.active.where(manager_id: nil).each do |u|
  c = User.find_by id: u.parent_id
  next unless c
  m = Member.find_by user_id: c.id, organization_id: u.organization_id
  next unless m
  u.update(manager: m)
  print '.'
end; nil
