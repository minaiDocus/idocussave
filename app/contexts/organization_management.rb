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
