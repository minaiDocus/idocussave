class AccountNumberFinderService
  def initialize(user, operation, temporary_account='471000')
    @user = user
    @operation = operation
    @temporary_account = temporary_account
  end

  def execute
    number = nil

    rules = @operation.user.rules + @operation.user.organization.rules.where(affect: 'organization')
    rules.sort_by(:priority)!
    number = match_rules(rules, @operation.label)
    unless number.present?
      accounting_plan = get_accounting_plan(@user)
      if accounting_plan.count != 0
        number = match_accounting_plan(accounting_plan, rules, @operation.label)
      end
      number = @temporary_account unless number.present?
    end
    number
  end

  class << self

    def check_matches(label, matches_score)
      words = label.split(' ')
      words.each do |word|
        matches.each do |name, score|
          if name.match /#{Regexp.quote(word)}/i
            score += 1
          end
        end
      end
      matches.sort_by{|n, s| s}.reverse!
      matches.first
    end

    def match_rules(rules, label)
      number = nil
      matches_score = Array.new

      match_rules = rules.select{ |rule| rule.rule_type == "match" }
      matches = match_rules.select{ |rule| label.match /#{Regexp.quote(rule.content)}/i }
      matches.each do |match|
        matches_score << [match.content, 0]
      end
      check = check_matches(label, matches_score)
      result = matches.select { |match| match[0] == check[0]}.first
      number = result.third_party_account if result
      number
    end

    def match_accounting_plan(accounting_plan, rules, label)
      number = nil
      matches = Array.new
      matches_score = Array.new

      truncate_rules = rules.select{|rule| rule.rule_type == "truncate" }
      matches += truncate_rules.select do |rule|
        accounting_plan.select{ |provider| label.match /#{Regexp.quote(provider[0].gsub(/ ?#{rule.content}/i, ""))}/i }
      end
      matches += accountingPlan.select { |provider| label.match /#{Regexp.quote(provider[0])}/i }
      matches.uniq!
      matches.each do |match|
        matches_score << [match[0], 0]
      end
      check = check_matches(label, matches_score)
      result = matches.select { |match| match[0] == check[0]}.first
      number = result[1] if result
      number
    end

    def get_accounting_plan(user)
      accounting_plan = Array.new
      if user.organization.ibiza.try(:is_configured?)
        doc = parsed_open_accounting_plan(user.code)
        if doc
          doc.css('wsAccounts').each do |provider|
            accounting_plan << [provider.css('name').text , provider.css('number').text]
          end
        end
      elsif user.accounting_plan
        user.accounting_plan.providers.each do |provider|
          accounting_plan << [provider.third_party_name , provider.third_party_account]
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
      path = File.join([Rails.root, 'data', 'compta', 'mapping', "#{code}.xml"])
      if File.exist? path
        Nokogiri::XML(open(path))
      else
        nil
      end
    end
  end
end
