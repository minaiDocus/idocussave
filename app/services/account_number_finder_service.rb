class AccountNumberFinderService
  def initialize(user, temporary_account='471000')
    @user = user
    @temporary_account = temporary_account
    @rules = @user.account_number_rules
    @rules += @user.organization.account_number_rules.global
    @rules.sort_by!(&:priority)
  end

  def execute(label)
    number = nil
    number = self.class.find_with_rules(@rules, label) if @rules.any?
    number ||= self.class.find_with_accounting_plan(accounting_plan, label, @rules) if accounting_plan.size != 0
    number ||= @temporary_account
    number
  end

  def accounting_plan
    @accounting_plan ||= find_or_update_accounting_plan.map do |account|
      [account.third_party_name, account.third_party_account]
    end
  end

  def find_or_update_accounting_plan
    accounts = (@user.accounting_plan.customers + @user.accounting_plan.providers)
    if accounts.present?
      accounts
    elsif @user.accounting_plan.last_checked_at.nil? || @user.accounting_plan.last_checked_at <= 5.minutes.ago
      UpdateAccountingPlan.new(@user).execute
      (@user.accounting_plan.customers + @user.accounting_plan.providers)
    else
      []
    end
  end

  class << self
    def get_the_highest_match(label, names)
      scores = names.map do |name|
        [name, 0]
      end
      words = label.split(/\s+/)
      words.each do |word|
        scores.each_with_index do |(name, _), index|
          if name.include? '*'
            scores[index][1] += 1 if /#{Regexp.quote(name).gsub('\\ ', '|').gsub('\\*', '\w*')}/i.match word
          else
            scores[index][1] += 1 if name.match /#{Regexp.quote(word)}/i
          end
        end
      end
      scores.select{ |s| s[1] > 0 }.
        sort_by(&:last).last.try(:first)
    end

    def find_with_rules(rules, label)
      number = nil
      match_rules = rules.select{ |rule| rule.rule_type == 'match' }
      match_rules = match_rules.select{ |rule| label.match /#{Regexp.quote(rule.content.gsub('*', ''))}/i }
      name = get_the_highest_match(label, match_rules.map(&:content))
      result = match_rules.select { |match| match.content == name }.first
      number = result.third_party_account if result
      number
    end

    def find_with_accounting_plan(accounting_plan, label, rules=[])
      number = nil
      truncate_rules = rules.select { |rule| rule.rule_type == 'truncate' }

      matches = truncate_rules.map do |rule|
        accounting_plan.select do |account|
          clean_name = account[0].gsub(/ ?#{Regexp.quote(rule.content)}/i, '')
          label.match /#{Regexp.quote(clean_name)}/i
        end
      end.flatten(1)
      matches += accounting_plan.select { |account| label.match /#{Regexp.quote(account[0])}/i }
      matches.uniq!
      name = get_the_highest_match(label, matches.map(&:first))
      result = matches.select { |match| match[0] == name }.first
      number = result[1] if result
      number
    end
  end
end
