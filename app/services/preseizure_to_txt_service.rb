# -*- encoding : UTF-8 -*-
class PreseizureToTxtService
  def initialize(preseizures)
    @preseizures = Array(preseizures)
  end

  def execute
    data = []
    @preseizures.each do |preseizure|
      preseizure.entries.each do |entry|
        string = [preseizure.third_party.presence, preseizure.observation.presence].compact.join('. ')
        labels = string.split('').in_groups_of(30).map(&:join)
        labels = [' '] unless labels.any?
        line = ' '*256
        labels.each_with_index do |label, index|
          if index == 0
            line[0] = 'M'
            account_number = entry.account.try(:number) || ''
            line[1..8]     = account_number[0..7] + (' ' * (8-account_number.size))
            line[9..10]    = preseizure.report.journal[0..1]
            line[11..13]   = '000'
            line[14..19]   = preseizure.date.strftime('%d%m%y') if preseizure.date
            e = 21 + label[0..19].size - 1
            line[21..e]    = label[0..19]
            line[41]       = entry.type == 1 ? 'D' : 'C'
            line[42]       = entry.amount >= 0.0 ? '+' : '-'
            line[43..54]   = "%012d" % (entry.amount * 100)
            line[63..68]   = preseizure.deadline_date.strftime('%d%m%y') if preseizure.deadline_date
            line[107..109] = 'EUR'
            line[110..112] = preseizure.report.journal[0..2] if preseizure.report.journal.size > 2
            if label.size > 20
              e = 116 + label.size - 1
              line[116..e] = label
            end
            if preseizure.piece
              file_name = preseizure.piece.number.to_s + '.pdf'
              e = 181 + file_name.size - 1
              line[181..e] = file_name
            end
            data << line
          else
            line2 = line.dup
            line2[21..40]   = ' '*20
            e = 21 + label[0..19].size - 1
            line2[21..e]    = label[0..19]
            line2[41..54]   = '          0000'
            line2[116..145] = ' '*30
            if label.size > 20
              e = 116 + label.size - 1
              line2[116..e] = label
            end
            data << line2
          end
        end
      end
    end
    data.join("\n")
  end
end
