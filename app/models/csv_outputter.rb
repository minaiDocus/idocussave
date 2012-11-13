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
      preseizure.entries.by_position.each do |entry|
        lines << format_line(entry)
      end
    end
    lines.join("\n")
  end

  def format_line(entry)
    line = ''
    to_a.each do |part|
      result = case part[1]
        when /^date$/
          format = part[2].presence || "%d/%m/%Y"
          entry.preseizure.date.try(:strftime,format) || ''
        when /^period_date$/
          format = part[2].presence || "%d/%m/%Y"
          result = entry.preseizure.date < entry.preseizure.period_date rescue true
          if result
            entry.preseizure.period_date.try(:strftime,format) || ''
          else
            entry.preseizure.date.try(:strftime,format) || ''
          end
        when /^deadline_date$/
          format = part[2].presence || "%d/%m/%Y"
          entry.preseizure.deadline_date.try(:strftime,format) || ''
        when /^type$/
          entry.preseizure.report.type
        when /^client_code$/
          entry.preseizure.report.pack.owner.code
        when /^journal$/
          entry.preseizure.piece.name.split(' ')[1]
        when /^period$/
          entry.preseizure.piece.name.split(' ')[2]
        when /^piece_number$/
          entry.preseizure.piece.name.split(' ')[3].to_i
        when /^original_piece_number$/
          entry.preseizure.piece_number
        when /^piece$/
          entry.preseizure.piece.try(:name).try(:gsub,' ','_')
        when /^original_amount$/
          entry.preseizure.amount
        when /^currency$/
          entry.preseizure.currency
        when /^conversion_rate$/
          entry.preseizure.conversion_rate
        when /^piece_url$/
          'http://www.idocus.com'+entry.preseizure.piece.get_access_url
        when /^remark$/
          entry.preseizure.observation
        when /^third_party$/
          entry.preseizure.third_party
        when /^number$/
          entry.account.number
        when /^debit$/
          entry.get_debit
        when /^credit$/
          entry.get_credit
        when /^title$/
          '' # TODO implement me
        when /^lettering$/
          entry.account.lettering
        else ''
      end
      line += "#{part[0]}#{result}#{part[3]}"
    end
    line
  end
end
