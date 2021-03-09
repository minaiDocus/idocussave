# -*- encoding : UTF-8 -*-
# Generates a Quadratus compliant TXT for preseizures
class PreseizureExport::PreseizureToTxt
  def initialize(preseizures)
    @preseizures = Array(preseizures)
  end


  def execute(type_of_export="zip_quadratus")
    if type_of_export == "zip_quadratus"
      export_zip_quadratus
    elsif type_of_export == "cegid_tra"
      export_cegid_tra
    else
      export_fec_agiris
    end
  end

  private

  def export_zip_quadratus
    data = []
    @preseizures.each do |preseizure|
      preseizure.entries.each do |entry|
        if preseizure.operation
          label = preseizure.operation_label[0..29]
        else
          label = [preseizure.third_party.presence, preseizure.piece_number.presence].compact.join(' - ')[0..29]
        end

        label = ' ' unless label.present?
        line = ' ' * 256
        line[0] = 'M'
        account_number = entry.account.try(:number) || ''

        8.times do |i|
          line[i + 1] = account_number[i] || ' '
        end

        line[9..10]    = preseizure.journal_name[0..1]
        line[11..13]   = '000'
        line[14..19]   = preseizure.computed_date.strftime('%d%m%y') if preseizure.date

        e = 21 + label[0..19].size - 1

        line[21..e]    = label[0..19]
        line[41]       = entry.type == 1 ? 'D' : 'C'
        line[42]       = entry.amount >= 0.0 ? '+' : '-'
        line[43..54]   = '%012d' % entry.amount_in_cents
        line[63..68]   = preseizure.deadline_date.strftime('%d%m%y') if preseizure.deadline_date
        line[69..73]   = entry.account.lettering[0..4] if entry.account.lettering.present?
        line[74..78]   = preseizure.piece_number[0..4] if preseizure.piece_number.present?
        line[99..106]  = preseizure.piece_number[0..7] if preseizure.piece_number.present?
        line[107..109] = 'EUR'
        line[110..112] = preseizure.journal_name[0..2] if preseizure.journal_name.size > 2

        if label.size > 20
          e = 116 + label.size - 1
          line[116..e] = label
        end

        line[148..157] = preseizure.piece_number[0..9].rjust(10, '0') if preseizure.piece_number.present?

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

  def export_cegid_tra
    data = []

    line      = ' ' * 222
    line[0]   = '***S5EXPJRLSTD'
    line[33]  = '011'
    line[53]  = 'IDOCUS'
    line[144] = '001'
    line[147]  = '-'
    line[148]  = '-'

    data << line

    @preseizures.each do |preseizure|
      if preseizure.operation
        label = preseizure.operation_label[0..29]
      else
        label = [preseizure.third_party.presence, preseizure.piece_number.presence].compact.join(' - ')[0..29]
      end

      if preseizure.piece
        journal = preseizure.report.pack.journal
        nature = case journal.compta_type
                 when 'AC'
                  if preseizure.entries.where(type: 2).count > 1
                    'AF'
                  else
                    'FF'
                  end
                 when 'VT'
                  if preseizure.entries.where(type: 1).count > 1
                    'FC'
                  else
                    'AC'
                  end
                 when 'NDF'
                  'OD'
                 end

        preseizure.entries.each do |entry|
          account = case nature
                    when 'AF'
                      if entry.account.type == Pack::Report::Preseizure::Account::TTC
                        '401000'
                      else
                        entry.account.try(:number)
                      end
                    when 'FF'
                      if entry.account.type == Pack::Report::Preseizure::Account::TTC
                        '401000'
                      else
                        entry.account.try(:number)
                      end
                    when 'AC'
                      if entry.account.type == Pack::Report::Preseizure::Account::TTC
                        '411000'
                      else
                        entry.account.try(:number)
                      end
                    when 'FC'
                      if entry.account.type == Pack::Report::Preseizure::Account::TTC
                        '411000'
                      else
                        entry.account.try(:number)
                      end
                    end


            label = ' ' unless label.present?
            line = ' ' * 222
            line[0] = preseizure.journal_name[0..2]
            line[3..11] = preseizure.computed_date.strftime('%d%m%Y') if preseizure.date
            line[11] = nature
            line[13] = account

            line[30] = 'X' if entry.account.type == Pack::Report::Preseizure::Account::TTC

            account_number = entry.account.try(:number) || ''
            line[31] = account_number if entry.account.type == Pack::Report::Preseizure::Account::TTC

            line[48] = preseizure.piece_number? ? preseizure.piece_number : preseizure.third_party

            line[83] = I18n.transliterate(label)

            line[129] = entry.type == 1 ? 'D' : 'C'

            amount = sprintf("%.2f", entry.amount.to_f).to_s.gsub('.', ',')
            window = 150 - amount.size

            line[window..150] = amount

            line[150] = 'N'
            line[151] = preseizure.piece.number.to_s
            line[172] = 'E--'

            data << line

            file_name = preseizure.piece.name.tr(' ', '_').tr('%', '_') + '.pdf'

            line = ' ' * 222

            if entry.account.type == Pack::Report::Preseizure::Account::TTC
              line[0] = preseizure.journal_name[0..2]
              line[3..11] = preseizure.computed_date.strftime('%d%m%Y') if preseizure.date
              line[11] = nature
              line[13] = case journal.compta_type
                         when 'AC'
                          '401000'
                         when 'VT'
                          '411000'
                         when 'NDF'
                          '471000'
                         end

              line[30] = 'G'
              line[31] = Pack::Report::Preseizure::Account.where(id: preseizure.entries.pluck(:account_id)).where(type: Pack::Report::Preseizure::Account::TTC).first.try(:number)
              line[48] = preseizure.piece_number? ? preseizure.piece_number : preseizure.third_party
              line[83] = file_name

              data << line
            end

        end
      end
    end

    data.join("\n")
  end

  def export_fec_agiris
    data = []

    if @preseizures.any?
      data << "JournalCode\tJournalLib\tEcritureNum\tEcritureDate\tCompteNum\tCompteLib\tCompAuxNum\tCompAuxLib\tPieceRef\tPieceDate\tEcritureLibc\tDebit\tCredit\tEcritureLet\tDateLet\tValidDate\tMontantdevise\tIdevise"

      @preseizures.each do |preseizure|
        user = preseizure.user
        journal = preseizure.report.journal({name_only: false})

        preseizure.accounts.each do |account|
          entry = account.entries.first

          if preseizure.piece_id.present?
            general_account = if(account.type == Pack::Report::Preseizure::Account::TVA)
                                journal.try(:get_vat_accounts_of, '0')
                              elsif(account.type == Pack::Report::Preseizure::Account::TTC)
                                journal.try(:account_number)
                              else
                                journal.try(:charge_account)
                              end
          else
            bank_account = preseizure.operation.try(:bank_account)

            general_account = if(
                                  (preseizure.operation.try(:amount).to_i < 0 && entry.credit?) ||
                                  (preseizure.operation.try(:amount).to_i >= 0 && entry.debit?)
                                )
                                bank_account.try(:accounting_number) || 512_000
                              else
                                bank_account.try(:temporary_account) || 471_000
                              end
          end

          auxiliary_account = (general_account.to_s != account.number.to_s)? account.number : ''
          auxiliary_lib     = ""

          if auxiliary_account.present?
            if preseizure.piece_id.present?
              accounting = user.accounting_plan.providers.where(third_party_account: auxiliary_account).limit(1)
              is_provider = accounting.size > 0

              unless is_provider
                accounting = user.accounting_plan.customers.where(third_party_account: auxiliary_account).limit(1)
                is_customer = accounting.size > 0
              end

              general_account = if is_provider
                                  40_100_001
                                elsif is_customer
                                  41_100_001
                                else
                                  auxiliary_account
                                end


              auxiliary_account = ''                                unless is_provider || is_customer
              auxiliary_lib     = accounting.first.third_party_name if is_provider || is_customer
            else
              if general_account != bank_account.try(:accounting_number) && general_account != 512_000
                general_account = if entry.debit?
                                    40_100_001
                                  else
                                    41_100_001
                                  end
              end
            end
          end

          label = preseizure.piece.try(:name)
          label = preseizure.operation_label[0..34].gsub("\t", ' ') if preseizure.operation_label.present?

          journal_code   = preseizure.journal_name || ""
          journal_lib    = user.account_book_types.where(name: journal_code).first.try(:description).try(:gsub, "\t", ' ').try(:tr, '()', '  ') || ""
          ecriture_num   = ""
          ecriture_date  = preseizure.date.strftime('%Y%m%d') || ""
          compte_num     = general_account || ""
          compte_lib     = ""
          comp_aux       = auxiliary_account || ""
          comp_aux_lib   = auxiliary_lib || ""
          piece_ref      = preseizure.piece_number || ""
          piece_date     = preseizure.date.strftime('%Y%m%d') || ""
          ecriture_libc  = label || ""
          debit_credit   = entry.type == 1 ? entry.amount.to_f.to_s + "\t0" : "0\t" + entry.amount.to_f.to_s
          ecriture_let   = account.lettering || ""
          date_let       = ""
          valid_date     = ""
          montant_devise = preseizure.amount.to_f.to_s || ""
          idevise        = preseizure.amount.to_f > 0 ? preseizure.currency.to_s : ""

          data << [[journal_code, journal_lib, ecriture_num, ecriture_date, compte_num, compte_lib, comp_aux, comp_aux_lib, piece_ref, piece_date, ecriture_libc, debit_credit, ecriture_let, date_let, valid_date, montant_devise, idevise].join("\t")]
        end
      end
    end

    data.join("\n")
  end
end
