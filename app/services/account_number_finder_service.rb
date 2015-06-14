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
    @accounting_plan ||= self.class.get_accounting_plan(@user)
  end

  class << self
    def get_the_highest_match(label, names)
      scores = names.map do |name|
        [name, 0]
      end
      words = label.split(/\s+/)
      words.each do |word|
        scores.each do |name, score|
          score += 1 if name.match /#{Regexp.quote(word)}/i
        end
      end
      scores.sort_by(&:last).last.try(:first)
    end

    def find_with_rules(rules, label)
      number = nil
      match_rules = rules.select{ |rule| rule.rule_type == 'match' }
      match_rules = match_rules.select{ |rule| label.match /#{Regexp.quote(rule.content)}/i }
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

    def get_accounting_plan(user)
      accounting_plan = []
      if user.organization.ibiza.try(:is_configured?)
        doc = parsed_open_accounting_plan(user.code)
        if doc
          doc.css('wsAccounts').each do |account|
            accounting_plan << [account.css('name').text, account.css('number').text]
          end
        end
      elsif user.accounting_plan
        user.accounting_plan.providers.each do |provider|
          accounting_plan << [provider.third_party_name, provider.third_party_account]
        end
      end
      accounting_plan
    end

    def parsed_open_accounting_plan(code)
      accounting_plan = parsed_accounting_plan(code)
      if accounting_plan
        closed_account = accounting_plan.css('closed').select{ |closed| closed.text == '1' }
        closed_account.each do |account|
          account.parent.remove
        end
        accounting_plan
      else
        nil
      end
    end

    def parsed_accounting_plan(code)
      path = Rails.root.join('data', 'compta', 'mapping', "#{code}.xml").to_s
      if File.exist? path
        Nokogiri::XML(open(path))
      else
        nil
      end
    end
  end
end
