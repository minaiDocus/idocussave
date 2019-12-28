### Migrate data for membership system

puts 'Create a membership for each collaborator'
User.transaction do
  User.prescribers.each do |u|
    m = Member.find_by user_id: u.id, organization_id: u.organization_id
    next if m
    next if u.organization.nil?

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

    # Empties organization_id and code from collaborator since they will not be used anymore
    # user.update(code: nil, organization_id: nil) if member.persisted?

    print '.'
  end
end; nil

# Problem : "MVN%#NBT" has an invalid character in his/her code

class GroupsUsers < ApplicationRecord
  belongs_to :group
  belongs_to :user
end

puts 'Reassign group membership from collaborator to member'
Group.all.each do |g|
  g.users.prescribers.each do |u|
    m = Member.find_by user_id: u.id, organization_id: g.organization_id
    next unless m
    next if m.groups.include?(g)
    m.groups << g
    m.save
    print '.'
  end

  # Cleanup old relations
  # GroupsUsers.joins(:user).where(users: { is_prescriber: true }).delete_all
end; nil

puts 'Migrate parent/child relationship'
User.customers.active.where(manager_id: nil).each do |u|
  c = User.find_by id: u.parent_id
  next unless c
  m = Member.find_by user_id: c.id, organization_id: u.organization_id
  next unless m
  u.update(manager: m)
  print '.'
end; nil

puts 'Done'
