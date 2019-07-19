class AccountNumberFinderService
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

    label  = @operation.label
    target = @operation.amount < 0 ? 'credit' : 'debit'

    number =  self.class.find_with_rules(@rules, label, target) if @rules.any?
    number ||= self.class.find_with_accounting_plan(accounting_plan, label, target, @rules) unless accounting_plan.empty?
    number ||= @temporary_account

    number
  end


  def accounting_plan
    @accounting_plan ||= find_or_update_accounting_plan.map do |account|
      [account.third_party_name, account.third_party_account]
    end
  end


  def find_or_update_accounting_plan
    if @operation.amount < 0 #credit
      accounts = @user.accounting_plan.providers
    else #debit
      accounts = @user.accounting_plan.customers
    end

    if accounts.present?
      accounts
    elsif @user.accounting_plan.last_checked_at.nil? || @user.accounting_plan.last_checked_at <= 5.minutes.ago
      UpdateAccountingPlan.new(@user).execute

      if @operation.amount < 0 #credit
        @user.accounting_plan.providers
      else #debit
        @user.accounting_plan.customers
      end
    else
      []
    end
  end


  def self.get_the_highest_match(label, names)
    scores = names.map do |name|
      [name, 0]
    end

    words = label.split(/\s+/)

    words.each do |word|
      scores.each_with_index do |(name, _), index|
        if name.include? '*'
          scores[index][1] += 1 if /#{Regexp.quote(name).gsub('\\ ', '|').gsub('\\*', '\w*')}/i =~ word
        else
          scores[index][1] += 1 if name =~ /#{Regexp.quote(word)}/i
        end
      end
    end

    scores.select { |s| s[1] > 0 }.sort_by(&:last).last.try(:first)
  end


  def self.find_with_rules(rules, label, target)
    number = nil

    match_rules = rules.select { |rule| rule.rule_target == 'both' || rule.rule_target == target }
    match_rules = match_rules.select { |rule| rule.rule_type == 'match' }
    match_rules = match_rules.select { |rule| label.match /#{Regexp.quote(rule.content.delete('*'))}/i }

    name = get_the_highest_match(label, match_rules.map(&:content))

    result = match_rules.select { |match| match.content == name }.first

    number = result.third_party_account if result
    number
  end


  def self.find_with_accounting_plan(accounting_plan, label, target, rules = [])
    number = nil

    truncate_rules = rules.select { |rule| rule.rule_target == 'both' || rule.rule_target == target }
    truncate_rules = truncate_rules.select { |rule| rule.rule_type == 'truncate' }

    matches = truncate_rules.flat_map do |rule|
      accounting_plan.select do |account|
        clean_name = account[0].gsub(/ ?#{Regexp.quote(rule.content)}/i, '')
        label.match /#{Regexp.quote(clean_name)}/i
      end
    end

    matches += accounting_plan.select { |account| label.match /#{Regexp.quote(account[0])}/i }

    matches.uniq!

    name = get_the_highest_match(label, matches.map(&:first))

    result = matches.select { |match| match[0] == name }.first
    
    number = result[1] if result
    number
  end
end
