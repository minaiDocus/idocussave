class Collaborator
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
    @user.is_admin || member.admin?
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

  def customers
    if @organization
      member.customers
    else
      all_customers
    end
  end

  def all_customers
    return @all_customers if @all_customers

    organization_ids = @user.memberships.select(&:admin?).map(&:organization_id)
    member_ids       = @user.memberships.map(&:id)

    @all_customers = User.customers.joins(groups: :groups_members).
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
