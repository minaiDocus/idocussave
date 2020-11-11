# -*- encoding : UTF-8 -*-
class PonctualScripts::Archive::GenerateUsersAccessGroup
  class << self

    def execute
      p start_time = Time.now
      File.open Rails.root.join('files', 'users_access_group.txt'), 'w' do |f|
        customers = User.customers.active
        p customers.size
        customers.each do |customer|
          access_group_emails = [customer.email] | ( customer.prescribers.map(&:email) || [] ) | ( customer.inverse_account_sharings.map(&:collaborator).map(&:email) || [] )
          f.write "#{customer.code.gsub(/[%]/, '_')} : #{access_group_emails.join(',')}\n" if access_group_emails.any?
        end
      end;nil
      p Time.now
      p end_time = Time.now - start_time
    end

  end

end
