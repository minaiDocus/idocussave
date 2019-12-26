# frozen_string_literal: true

module Account::Organization::CustomersHelper
  def managers_options_for_select
    @organization.members
                 .joins(:user)
                 .order('users.first_name asc, users.last_name asc')
                 .map { |m| [m.name, m.id] }
  end
end
