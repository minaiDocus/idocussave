# -*- encoding : UTF-8 -*-
# Generate a CSV for preseizure collections depending on user csv descriptor
class PreseizuresToCsv
  def initialize(user, preseizures)
    @user = user
    @descriptor  = descriptor
    @preseizures = preseizures

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
                 format = part[1].presence || 'AAAA/MM/JJ'
                 format.gsub!(/AAAA/, '%Y')
                 format.gsub!(/AA/, '%y')
                 format.gsub!(/MM/, '%m')
                 format.gsub!(/JJ/, '%d')
                 entry.preseizure.date.try(:strftime, format) || ''
               when /\Aperiod_date\z/
                 format = part[1].presence || 'AAAA/MM/JJ'
                 format.gsub!(/AAAA/, '%Y')
                 format.gsub!(/AA/, '%y')
                 format.gsub!(/MM/, '%m')
                 format.gsub!(/JJ/, '%d')
                 res = begin
                         entry.preseizure.date < entry.preseizure.period_date || entry.preseizure.date > entry.preseizure.end_period_date
                         rescue
                           true
                         end

                 if res
                   entry.preseizure.period_date.try(:strftime, format) || ''
                 else
                   entry.preseizure.date.try(:strftime, format) || ''
                 end
               when /\Adeadline_date\z/
                 format = part[1].presence || 'AAAA/MM/JJ'
                 format.gsub!(/AAAA/, '%Y')
                 format.gsub!(/AA/, '%y')
                 format.gsub!(/MM/, '%m')
                 format.gsub!(/JJ/, '%d')
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
                ('%0.2f' % entry.preseizure.amount).gsub(/[\.,\,]/, @descriptor.separator) if entry.preseizure.amount
               when /\Acurrency\z/
                 entry.preseizure.currency.to_s.gsub(/[\.,\,]/, @descriptor.separator)
               when /\Aconversion_rate\z/
                 conversion_rate = begin
                                     '%0.3f' % entry.preseizure.conversion_rate
                                   rescue
                                     ''
                                   end
                 conversion_rate.to_s.gsub(/[\.,\,]/, @descriptor.separator)
               when /\Apiece_url\z/
                 if @user.is_access_by_token_active
                   "https://my.idocus.com" + entry.preseizure.piece.try(:get_access_url)
                 else
                   "https://my.idocus.com" + entry.preseizure.piece_content_url
                 end
               when /\Aremark\z/
                 entry.preseizure.observation
               when /\Athird_party\z/
                 entry.preseizure.third_party
               when /\Anumber\z/
                 entry.account.number
               when /\Adebit\z/
                 ('%0.2f' % entry.get_debit).gsub(/[\.,\,]/, @descriptor.separator) if entry.get_debit
               when /\Acredit\z/
                 ('%0.2f' % entry.get_credit).gsub(/[\.,\,]/, @descriptor.separator) if entry.get_credit
               when /\Aoperation_label\z/
                 entry.preseizure.operation_label
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
