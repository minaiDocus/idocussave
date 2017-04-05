class OrganizationManagement
  module Common
    def _organization
      organization || my_organization
    end

    def customer_ids
      customers.map(&:id)
    end

    def packs
      Pack.where("owner_id = ? OR (organization_id = ? AND owner_id IN (?))", id, _organization.id, customer_ids)
    end

    def temp_packs
      TempPack.where(user_id: customer_ids)
    end


    def can_manage_collaborators?
      organization_rights_is_collaborators_management_authorized
    end

    def cannot_manage_collaborators?
      !can_manage_collaborators?
    end

    def can_manage_customers?
      organization_rights_is_customers_management_authorized
    end

    def cannot_manage_customers?
      !can_manage_customers?
    end

    def can_manage_groups?
      organization_rights_is_groups_management_authorized
    end

    def cannot_manage_groups?
      !can_manage_groups?
    end

    def can_manage_journals?
      organization_rights_is_journals_management_authorized
    end

    def cannot_manage_journals?
      !can_manage_journals?
    end
  end

  module Leader
    include Common

    def customers
      _organization.customers
    end
  end

  module Collaborator
    include Common

    def customers
      _organization.customers.joins(:groups).where("groups.id IN (?)", self.group_ids).distinct
    end
  end
end
