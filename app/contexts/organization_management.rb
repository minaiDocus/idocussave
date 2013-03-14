class OrganizationManagement
  module Common
    def _organization
      self.organization || self.my_organization
    end

    def customer_ids
      customers.map(&:_id)
    end

    def packs
      Pack.any_of({
                    organization_id: _organization.id,
                    :user_ids.in => customer_ids
                  },
                  {
                    :user_ids.in => [self.id]
                  })
    end

    def rights
      find_or_create_organization_rights
    end

    def can_manage_customers?
      rights.is_customers_management_authorized
    end

    def cannot_manage_customers?
      !can_manage_customers?
    end

    def can_manage_groups?
      rights.is_groups_management_authorized
    end

    def cannot_manage_groups?
      !can_manage_groups?
    end

    def can_manage_journals?
      rights.is_journals_management_authorized
    end

    def cannot_manage_journals?
      !can_manage_journals?
    end
  end

  module Leader
    include Common

    def customers
      self._organization.customers
    end
  end

  module Collaborator
    include Common

    def customers
      self._organization.customers.any_in(group_ids: self['group_ids'])
    end
  end
end
