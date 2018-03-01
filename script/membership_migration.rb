### Migrate data for membership system

puts 'Create a membership for each collaborator'
User.transaction do
  User.prescribers.each do |u|
    m = Member.find_by user_id: u.id, organization_id: u.organization_id
    next if m

    if u.organization.leader_id == u.id || u.is_admin
      role = Member::ADMIN
    else
      role = Member::COLLABORATOR
    end

    member = Member.create(
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

    # empties organization_id for collaborator
    # removes code from user
    # user.update(code: nil, organization_id: nil) if member.persisted?

    print '.'
  end
end

# TODO : create membership to all 3 organizations for Extentis

puts 'Reassign group membership from collaborator to member'
Group.all.each do |g|
  g.users.prescribers.each do |u|
    m = Member.find_by user_id: u.id, organization_id: g.organization_id
    next if m.groups.include?(g)
    m.groups << g
    m.save
    print '.'
  end
end

puts 'Migrate parent/child relationship'
User.customers.active.where(manager_id: nil).each do |u|
  c = User.find_by id: u.parent_id
  next unless c
  m = Member.find_by user_id: c.id, organization_id: u.organization_id
  next unless m
  u.update(manager: m)
  print '.'
end

puts 'Done'
