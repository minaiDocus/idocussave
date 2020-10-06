class Collaborator
  attr_reader :user

  def initialize(user, member: nil, organization: nil)
    @user         = user
    @member       = member
    @organization = organization
  end

  def with_scope(member, organization)
    @member       = member
    @organization = organization
  end

  def with_organization_scope(organization)
    @organization = organization
    @member = Member.find_by(organization: @organization, user: @user)
  end

  def scoped?
    @member.present?
  end

  def member
    @member || @user.memberships.first
  end

  def organization
    @organization || member.organization
  end

  def code
    member.code
  end

  def admin?
    @user.is_admin
  end

  def leader?
    @user.is_admin || (@member && @member.admin?)
  end

  def not_leader?
    not leader?
  end

  def collaborator?
    @user.is_prescriber
  end

  def has_one_organization?
    @user.organizations.count == 1
  end

  def has_many_organization?
    @user.organizations.count > 1
  end

  def organizations_suspended?
    organizations.detect(&:is_suspended)
  end

  def organizations_not_suspended?
    not organizations_suspended?
  end

  def can_unsuspend?
    if @organization
      @organization.admins.include?(@user)
    else
      organizations.detect { |o| o.is_suspended && o.admins.include?(@user) }
    end
  end

  def customers
    if @organization
      admin? ? @organization.customers : member.customers
    else
      all_customers
    end
  end

  def all_customers
    return @all_customers if @all_customers

    organization_ids = @user.memberships.select(&:admin?).map(&:organization_id)
    member_ids       = @user.memberships.map(&:id)

    @all_customers = User.customers.joins('LEFT JOIN `groups_users` ON `groups_users`.`user_id` = `users`.`id` LEFT JOIN `groups` ON `groups`.`id` = `groups_users`.`group_id` LEFT JOIN `groups_members` ON `groups_members`.`group_id` = `groups`.`id`').
      where('groups_members.member_id IN (?) OR users.organization_id IN (?)', member_ids, organization_ids).distinct
  end

  def groups
    leader? ? organization.groups : member.groups
  end

  def temp_packs
    TempPack.where(user: customers)
  end

  def all_temp_packs
    TempPack.where(user: all_customers)
  end

  def invoices
    leader? ? Invoice.where(organization_id: organizations.map(&:id)) : Invoice.where(user_id: @user.id)
  end

  def method_missing(name, *args, &block)
    if @user.respond_to?(name)
      @user.send(name, *args, &block)
    else
      member.send(name, *args, &block)
    end
  end
end
