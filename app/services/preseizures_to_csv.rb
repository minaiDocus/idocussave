# -*- encoding : UTF-8 -*-
class PreseizuresToCsv
  def initialize(user, preseizures)
    @user = user
    @preseizures = preseizures
    @descriptor = descriptor
  end

  def execute
    lines = []
    @preseizures.each do |preseizure|
      preseizure.entries.by_position.each do |entry|
        lines << format_line(entry)
      end
    end
    lines.join("\n")
  end

private

  def descriptor
    if @user.options.is_own_csv_descriptor_used
      @user.csv_descriptor!
    else
      @user.organization.csv_descriptor!
    end
  end

  def format_line(entry)
    line = ''
    @descriptor.directive_to_a.each do |part|
      result = case part[0]
        when /\Adate\z/
          format = part[1].presence || "AAAA/MM/JJ"
          format.gsub!(/AAAA/, "%Y")
          format.gsub!(/AA/, "%y")
          format.gsub!(/MM/, "%m")
          format.gsub!(/JJ/, "%d")
          entry.preseizure.date.try(:strftime, format) || ''
        when /\Aperiod_date\z/
          format = part[1].presence || "AAAA/MM/JJ"
          format.gsub!(/AAAA/, "%Y")
          format.gsub!(/AA/, "%y")
          format.gsub!(/MM/, "%m")
          format.gsub!(/JJ/, "%d")
          res = entry.preseizure.date < entry.preseizure.period_date || entry.preseizure.date > entry.preseizure.end_period_date rescue true
          if res
            entry.preseizure.period_date.try(:strftime,format) || ''
          else
            entry.preseizure.date.try(:strftime, format) || ''
          end
        when /\Adeadline_date\z/
          format = part[1].presence || "AAAA/MM/JJ"
          format.gsub!(/AAAA/, "%Y")
          format.gsub!(/AA/, "%y")
          format.gsub!(/MM/, "%m")
          format.gsub!(/JJ/, "%d")
          entry.preseizure.deadline_date.try(:strftime, format) || ''
        when /\Aclient_code\z/
          entry.preseizure.report.user.code
        when /\Ajournal\z/
          entry.preseizure.report.journal
        when /\Aperiod\z/
          entry.preseizure.piece_name.try(:split).try(:[], 2)
        when /\Apiece_number\z/
          entry.preseizure.piece_name.try(:split).try(:[], 3).try(:to_i)
        when /\Aoriginal_piece_number\z/
          entry.preseizure.piece_number
        when /\Apiece\z/
          entry.preseizure.piece_name.try(:gsub, ' ', '_')
        when /\Aoriginal_amount\z/
          "#{entry.preseizure.amount}".gsub(/[\.,\,]/, @descriptor.separator)
        when /\Acurrency\z/
          "#{entry.preseizure.currency}".gsub(/[\.,\,]/, @descriptor.separator)
        when /\Aconversion_rate\z/
          conversion_rate = "%0.3f" % entry.preseizure.conversion_rate rescue ""
          "#{conversion_rate}".gsub(/[\.,\,]/, @descriptor.separator)
        when /\Apiece_url\z/
          if @user.is_access_by_token_active
            Settings.inner_url + entry.preseizure.piece.try(:get_access_url)
          else
            Settings.inner_url + entry.preseizure.piece_content_url
          end
        when /\Aremark\z/
          entry.preseizure.observation
        when /\Athird_party\z/
          entry.preseizure.third_party
        when /\Anumber\z/
          entry.account.number
        when /\Adebit\z/
          "#{entry.get_debit}".gsub(/[\.,\,]/, @descriptor.separator)
        when /\Acredit\z/
          "#{entry.get_credit}".gsub(/[\.,\,]/, @descriptor.separator)
        when /\Atitle\z/
          '' # TODO implement me
        when /\Alettering\z/
          entry.account.lettering
        when /\Aother\z/
          part[1].presence || ''
        when /\Aseparator\z/
          ';'
        else ''
      end
      line += result.to_s
    end
    line
  end
end
