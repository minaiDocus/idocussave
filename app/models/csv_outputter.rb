class CsvOutputter
  include Mongoid::Document
  include Mongoid::Timestamps

  field :directive, type: String, default: ""

  referenced_in :user

  def to_a
    directive.split(';')
  end

  # Pack::Preseizure
  def format(preseizures)
    lines = []
    preseizures.each do |preseizure|
      preseizure.accounts.each do |account|
        lines << format_line(account)
      end
    end
    lines.join("\n")
  end
  # bla;bla;bla\n
  # bla;bla;bla\n
  # bla;bla;bla\n
  # ...

  # Pack::Preseizure::Account
  def format_line(account)
    line = []
    to_a.each do |value|
      line << case value
        when /^:date/
          format = value.sub(/^date-/).presence || "%d/%m/%Y"
          account.preseizure.date.try(:strftime,format) || ''
        when ':type'
          account.preseizure.report.type
        when ':number'
          account.number
        when ':debit'
          account.debit
        when ':credit'
          account.credit
        when ':title'
          account.title
        when ':piece'
          account.preseizure.piece.try(:name).try(:gsub,' ','_')
        when ':lettering'
          account.lettering
        when /^:deadline_date/
          format = value.sub(/^deadline_date-/).presence || "%d/%m/%Y"
          account.preseizure.deadline_date.try(:strftime,format) || ''
        else ''
      end
    end
    line.join(";")
  end
  # bla;bla;bla\n
end
