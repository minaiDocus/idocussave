class PonctualScripts::MigrateMailToDigitizeOption < PonctualScripts::PonctualScript
  def self.execute(organization_code, user_id=[])
    new({code_org: organization_code, user_ids: user_id }).run
  end

  def self.rollback(organization_code, user_id=[])
    new({code_org: organization_code, user_ids: user_id }).rollback
  end

  private

  def execute
    organization = Organization.find_by_code @options[:code_org].to_s

    users = @options[:user_ids].any? ? User.where(id: @options[:user_ids]) : organization.users

    users.each do |user|
      subs = user.subscription.current_packages.tr('["\]','   ').tr('"', '').split(',').map { |pack| pack.strip } unless user.subscription.nil? || user.subscription.current_packages.nil?

      if subs && subs.include?('mail_option')
        user.subscription.current_packages = subs - ['mail_option'] + ['digitize_option']
        user.save
      end      
    end
  end

  def backup 
    organization = Organization.find_by_code @options[:code_org].to_s

    users = @options[:user_ids].any? ? User.where(id: @options[:user_ids]) : organization.users

    users.each do |user|
      subs = user.subscription.current_packages.tr('["\]','   ').tr('"', '').split(',').map { |pack| pack.strip } unless user.subscription.nil? || user.subscription.current_packages.nil?

      if subs && subs.include?('digitize_option')
        user.subscription.current_packages = subs - ['digitize_option'] + ['mail_option']
        user.save
      end      
    end
  end
end