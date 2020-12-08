class Transaction::AccountNumberFinder
  class << self
    def get_the_highest_match(label, names)
      scores = names.map do |name|
        [clean_txt(name), 0]
      end

      words = clean_txt(label).split(/\s+/)

      words.each do |word|
        scores.each_with_index do |(name, _), index|
          pattern = name.gsub('*', ' ').strip
          patterns = pattern.split(/\s+/)

          patterns.each{ |pt| scores[index][1] += 1 if word =~ /#{Regexp.quote(pt)}/i }
        end
      end

      scores.select { |s| s[1] > 0 }.sort_by(&:last).last.try(:first)
    end

    def find_with_rules(rules, label, target)
      number = nil

      match_rules = rules.select { |rule| rule.rule_target == 'both' || rule.rule_target == target }
      match_rules = match_rules.select { |rule| rule.rule_type == 'match' }
      match_rules = match_rules.select do |rule|
        search_pattern = clean_txt(rule.content)
        patterns = search_pattern.split('*')
        patterns << '' if rule.content.match(/.*[*]$/) #add a last empty string if there is a * at the end of the content
        pattern  = '\\b' + patterns.map{|pt| Regexp.quote(pt.strip) }.join('.*') + '\\b'
        clean_txt(label).match /#{pattern}/i
      end

      name = get_the_highest_match(label, match_rules.map(&:content))

      result = match_rules.select { |match| clean_txt(match.content) == clean_txt(name) }.first

      number = result.third_party_account if result
      number
    end

    def find_with_accounting_plan(accounting_plan, label, target, rules = [])
      number = nil

      truncate_rules = rules.select { |rule| rule.rule_target == 'both' || rule.rule_target == target }
      truncate_rules = truncate_rules.select { |rule| rule.rule_type == 'truncate' }

      matches = truncate_rules.flat_map do |rule|
        accounting_plan.select do |account|
          clean_name = clean_txt(account[0]).gsub(/ ?#{Regexp.quote(clean_txt(rule.content))}/i, '')
          clean_txt(label).match /#{'\\b'+Regexp.quote(clean_name)+'\\b'}/i
        end
      end

      matches += accounting_plan.select { |account| clean_txt(label).match /#{'\\b'+Regexp.quote(clean_txt(account[0]))+'\\b'}/i }

      matches.uniq!

      name = get_the_highest_match(label, matches.map(&:first))

      result = matches.select { |match| clean_txt(match[0]) == clean_txt(name) }.first

      number = result[1] if result
      number
    end

    def clean_txt(string=nil)
      string = string.to_s.strip.gsub(/[,:='"&#|;_)}\-\]\/\\]/, ' ')
      string = string.gsub(/[!?%€$£({\[]/, '')
      string = string.gsub(/( )+/, ' ')
      string.strip
    end
  end

  def initialize(user, temporary_account = '471000')
    @user = user
    @temporary_account = temporary_account

    @rules = @user.account_number_rules
    @rules += @user.organization.account_number_rules.global
    @rules.sort_by!(&:priority)
  end


  def execute(operation)
    number = nil
    @operation = operation
    @accounting_plan = nil

    label  = @operation.label
    target = @operation.credit? ? 'credit' : 'debit'

    number =  self.class.find_with_rules(@rules, label, target) if @rules.any?
    number ||= self.class.find_with_accounting_plan(accounting_plan, label, target, @rules) unless accounting_plan.empty? || @user.options.try(:skip_accounting_plan_finder)
    number ||= @temporary_account


    number = validate_account(number) if @user.options.try(:keep_account_validation) && number != @temporary_account && accounting_plan.any? && !@user.options.try(:skip_accounting_plan_finder)

    number
  end


  def accounting_plan
    @accounting_plan ||= find_or_update_accounting_plan.map do |account|
      [account.third_party_name, account.third_party_account]
    end
  end


  def find_or_update_accounting_plan
    if @operation.credit?
      accounts = @user.accounting_plan.reload.active_providers
    else #debit
      accounts = @user.accounting_plan.reload.active_customers
    end

    if accounts.present?
      accounts
    elsif @user.accounting_plan.last_checked_at.nil? || @user.accounting_plan.last_checked_at <= 5.minutes.ago

      if @user.organization.ibiza.try(:configured?)
        AccountingPlan::IbizaUpdate.new(@user).run
      elsif @user.organization.try(:exact_online).try(:used?)
        AccountingPlan::ExactOnlineUpdate.new(@user).run
      end

      if @operation.credit?
        @user.accounting_plan.reload.active_providers
      else #debit
        @user.accounting_plan.reload.active_customers
      end
    else
      []
    end
  end

  private

  def validate_account(account_number)
    return account_number unless @user.uses?(:ibiza)

    if @operation.credit?
      item_found = @user.accounting_plan.providers.where(is_updated: true, third_party_account: account_number).first
    else
      item_found = @user.accounting_plan.customers.where(is_updated: true, third_party_account: account_number).first
    end

    item_found ? account_number : @temporary_account 
  end
end
