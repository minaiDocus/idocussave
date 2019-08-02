# -*- encoding : UTF-8 -*-
# Generate a CSV for preseizure collections depending on user csv descriptor
class PreseizuresToCsv
  def initialize(user, preseizures, export_to='default')
    @user = user
    @descriptor  = descriptor
    @preseizures = preseizures
    @export_to = export_to
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
    if @user.try(:softwares).try(:use_own_csv_descriptor_format)
      @user.csv_descriptor!
    else
      @user.organization.csv_descriptor!
    end
  end

  def format_line(entry)
    line = ''
    if @export_to == 'coala'
      line += coala_format entry
    elsif @export_to == 'cegid'
      line += cegid_format entry
    else
      line += standard_format entry
    end
    line
  end

  def coala_format(entry)
    fifth_column = entry.preseizure.third_party || entry.preseizure.operation_label
    fifth_column = [entry.preseizure.third_party, entry.preseizure.piece_number].join(' ') if ['NSA'].include?(entry.preseizure.organization.code)

    result =  [
                entry.preseizure.computed_date.try(:strftime, "%d/%m/%Y"),
                entry.preseizure.journal_name.downcase,
                entry.account.number,
                entry.preseizure.coala_piece_name,
                fifth_column,
                "#{entry.get_debit}".gsub(/[\.,\,]/, '.'),
                "#{entry.get_credit}".gsub(/[\.,\,]/, '.'),
                "E"
              ].join(';')
    return result.to_s
  end

  def cegid_format(entry)
    label = entry.preseizure.operation_name

    if entry.preseizure.piece_id.present?
      journal = entry.preseizure.report.journal({name_only: false})

      general_account = if(entry.account.type == Pack::Report::Preseizure::Account::TVA)
        journal.try(:vat_account)
      elsif(entry.account.type == Pack::Report::Preseizure::Account::TTC)
        journal.try(:account_number)
      else
        journal.try(:charge_account)
      end

      description           = entry.preseizure.organization.ibiza.try(:description).presence || {}
      description_separator = entry.preseizure.organization.ibiza.try(:description_separator).presence || ' - '

      description_name = IbizaAPI::Utils.description(entry.preseizure, description, description_separator)
      label = description_name.present? ? description_name : entry.preseizure.third_party
    else
      operation    = entry.preseizure.operation
      bank_account = operation.try(:bank_account)

      general_account = if(
                            (operation.try(:amount).to_i < 0 && entry.type == Pack::Report::Preseizure::Entry::CREDIT) ||
                            (operation.try(:amount).to_i >= 0 && entry.type == Pack::Report::Preseizure::Entry::DEBIT)
                          )
        bank_account.try(:accounting_number) || 512_000
      else
        bank_account.try(:temporary_account) || 471_000
      end

      label = entry.preseizure.operation_label[0..34].gsub(';', ',') if entry.preseizure.operation_label.present?
    end

    axiliary_account = (general_account.to_s != entry.account.number.to_s)? entry.account.number : ''

    result =  [
                entry.preseizure.computed_date.try(:strftime, "%d%m%Y"),
                entry.preseizure.journal_name.upcase[0..2],
                general_account,
                axiliary_account,
                entry.debit? ? 'D' : 'C',
                entry.amount,
                label
              ].join(';')
    return result.to_s
  end

  def standard_format(entry)
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
          entry.preseizure.journal_name
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
            Settings.first.inner_url + entry.preseizure.piece.try(:get_access_url)
          else
            Settings.first.inner_url + entry.preseizure.piece_content_url
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
        when /\Acomplete_unit\z/
          entry.preseizure.unit.try(:upcase)
        when /\Apartial_unit\z/
          entry.preseizure.unit.split(//).try(:first).try(:upcase)
        when /\Aoperation_label\z/
          entry.preseizure.operation_label
        when /\Alettering\z/
          entry.account.lettering
        when /\Aother\z/
          part[1].nil? ? '' : part[1]
        when /\Aseparator\z/
          ';'
        else ''
      end

      line += result.to_s
    end

    return line
  end
end
