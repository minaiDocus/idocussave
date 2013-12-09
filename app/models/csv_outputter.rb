class CsvOutputter
  include Mongoid::Document
  include Mongoid::Timestamps

  field :comma_as_number_separator, type: Boolean, default: false
  field :directive, type: String, default: ""

  belongs_to :organization
  belongs_to :user

  def to_a
    directive.split('|').map do |e|
      e.scan(/\{(.*)\}(\w+)-(.*)\{(.*)\}/).first
    end
  end

  def format(preseizures, is_access_url=true)
    lines = []
    preseizures.by_position.each do |preseizure|
      preseizure.entries.by_position.each do |entry|
        lines << format_line(entry, is_access_url)
      end
    end
    lines.join("\n")
  end

  def format_line(entry, is_access_url=true)
    line = ''
    to_a.each do |part|
      result = case part[1]
        when /^date$/
          format = part[2].presence || "%d/%m/%Y"
          entry.preseizure.date.try(:strftime,format) || ''
        when /^period_date$/
          format = part[2].presence || "%d/%m/%Y"
          result = entry.preseizure.date < entry.preseizure.period_date || entry.preseizure.date > entry.preseizure.end_period_date rescue true
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
          entry.preseizure.report.user.code
        when /^journal$/
          entry.preseizure.piece_name.try(:split).try(:[], 1)
        when /^period$/
          entry.preseizure.piece_name.try(:split).try(:[], 2)
        when /^piece_number$/
          entry.preseizure.piece_name.try(:split).try(:[], 3).try(:to_i)
        when /^original_piece_number$/
          entry.preseizure.piece_number
        when /^piece$/
          entry.preseizure.piece_name.try(:gsub, ' ', '_')
        when /^original_amount$/
          "#{entry.preseizure.amount}".gsub(/[\.,\,]/, separator)
        when /^currency$/
          "#{entry.preseizure.currency}".gsub(/[\.,\,]/, separator)
        when /^conversion_rate$/
          conversion_rate = "%0.3f" % entry.preseizure.conversion_rate rescue ""
          "#{conversion_rate}".gsub(/[\.,\,]/, separator)
        when /^piece_url$/
          if is_access_url
            SITE_INNER_URL + entry.preseizure.piece.try(:get_access_url)
          else
            SITE_INNER_URL + entry.preseizure.piece_content_url
          end
        when /^remark$/
          entry.preseizure.observation
        when /^third_party$/
          entry.preseizure.third_party
        when /^number$/
          entry.account.number
        when /^debit$/
          "#{entry.get_debit}".gsub(/[\.,\,]/, separator)
        when /^credit$/
          "#{entry.get_credit}".gsub(/[\.,\,]/, separator)
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

  def separator
    comma_as_number_separator ? ',' : '.'
  end

  def copy_to_users(user_ids)
    users = User.find user_ids
    users.each do |user|
      user.csv_outputter!.copy self
    end
  end

  def copy(other)
    self.comma_as_number_separator = other.comma_as_number_separator
    self.directive = other.directive
    save
  end
end
