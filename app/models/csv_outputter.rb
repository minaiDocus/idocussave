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
    preseizures.each do |preseizure|
      preseizure.accounts.each do |account|
        lines << format_line(account)
      end
    end
    lines.join("\n")
  end

  def format_line(account)
    line = ''
    to_a.each do |part|
      result = case part[1]
        when /date/
          format = part[2].presence || "%d/%m/%Y"
          account.preseizure.date.try(:strftime,format) || ''
        when /type/
          account.preseizure.report.type
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
        when /deadline_date/
          format = part[2].presence || "%d/%m/%Y"
          account.preseizure.deadline_date.try(:strftime,format) || ''
        else ''
      end
      line += part[0] + result + part[3]
    end
    line
  end
end
