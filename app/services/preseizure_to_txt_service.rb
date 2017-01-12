# -*- encoding : UTF-8 -*-
# Generates a Quadratus compliant TXT for preseizures
class PreseizureToTxtService
  def initialize(preseizures)
    @preseizures = Array(preseizures)
  end


  def execute
    data = []
    @preseizures.each do |preseizure|
      preseizure.entries.each do |entry|
        label = [preseizure.third_party.presence, preseizure.piece_number.presence].compact.join(' - ')[0..29]
        label = ' ' unless label.present?
        line = ' ' * 256
        line[0] = 'M'
        account_number = entry.account.try(:number) || ''

        8.times do |i|
          line[i + 1] = account_number[i] || ' '
        end

        line[9..10]    = preseizure.report.journal[0..1]
        line[11..13]   = '000'
        line[14..19]   = preseizure.date.strftime('%d%m%y') if preseizure.date

        e = 21 + label[0..19].size - 1

        line[21..e]    = label[0..19]
        line[41]       = entry.type == 1 ? 'D' : 'C'
        line[42]       = entry.amount >= 0.0 ? '+' : '-'
        line[43..54]   = '%012d' % entry.amount_in_cents
        line[63..68]   = preseizure.deadline_date.strftime('%d%m%y') if preseizure.deadline_date
        line[107..109] = 'EUR'
        line[110..112] = preseizure.report.journal[0..2] if preseizure.report.journal.size > 2

        if label.size > 20
          e = 116 + label.size - 1
          line[116..e] = label
        end

        if preseizure.piece
          file_name = preseizure.piece.position.to_s + '.pdf'
          e = 181 + file_name.size - 1
          line[181..e] = file_name
        end

        data << line
      end
    end

    data.join("\n")
  end
end
