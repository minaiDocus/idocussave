module OrganizationsHelper
  def is_editable?(member, organization, groups)
    if member.is_editable && organization.is_edit_authorized
      if groups.size == 0
        true
      else
        temp_groups = groups.select { |e| e['member_ids'].include? member.id }
        if temp_groups.size == 0
          true
        elsif temp_groups.size == 1
          temp_groups.first.is_edit_authorized
        else
          temp_groups.inject { |m,e| m.is_edit_authorized || e.is_edit_authorized }
        end
      end
    else
      false
    end
  end
end