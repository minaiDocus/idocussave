class CsvOutputter
  include Mongoid::Document
  include Mongoid::Timestamps

  field :directive, type: String, default: ""

  referenced_in :user

  def to_a
    directive.split('|').map do |e|
      e.scan(/\{(.*)\}(\w+)-(.*)\{(.*)\}/).first
    end
  end

  def format(preseizures)
    lines = []
    preseizures.by_position.each do |preseizure|
      preseizure.accounts.by_position.each do |account|
        lines << format_line(account)
      end
    end
    lines.join("\n")
  end

  def format_line(account)
    line = ''
    to_a.each do |part|
      result = case part[1]
        when /^date$/
          format = part[2].presence || "%d/%m/%Y"
          account.preseizure.date.try(:strftime,format) || ''
        when /^period_date$/
          format = part[2].presence || "%d/%m/%Y"
          account.preseizure.period_date.try(:strftime,format) || ''
        when /^deadline_date$/
          format = part[2].presence || "%d/%m/%Y"
          account.preseizure.deadline_date.try(:strftime,format) || ''
        when /type/
          account.preseizure.report.type
        when /client_code/
          account.preseizure.report.pack.owner.code
        when /journal/
          account.preseizure.piece.name.split(' ')[1]
        when /period/
          account.preseizure.piece.name.split(' ')[2]
        when /piece_number/
          account.preseizure.piece.name.split(' ')[3].to_i
        when /original_piece_number/
          account.preseizure.piece_number
        when /piece/
          account.preseizure.piece.name
        when /original_amount/
          account.preseizure.amount
        when /currency/
          account.preseizure.currency
        when /conversion_rate/
          account.preseizure.conversion_rate
        when /piece_url/
          account.preseizure.piece.get_access_url
        when /remark/
          account.preseizure.observation
        when /third_party/
          account.preseizure.third_party
        when /number/
          account.number
        when /debit/
          account.debit
        when /credit/
          account.credit
        when /title/
          account.title
        when /piece/
          account.preseizure.piece.try(:name).try(:gsub,' ','_')
        when /lettering/
          account.lettering
        else ''
      end
      line += part[0] + result + part[3]
    end
    line
  end
end
