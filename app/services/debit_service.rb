class DebitService
  class << self
    def order(invoice_time, debit_date)
      data = DebitMandate.all.map do |debit_mandate|
        if debit_mandate.user.try(:is_prescriber)
          subject = debit_mandate.user.try(:organization)
        else
          subject = debit_mandate.user
        end
        if subject
          invoice = subject.invoices.where(
            :created_at.gte => invoice_time.beginning_of_month,
            :created_at.lte => invoice_time.end_of_month,
          ).first
          invoice ? [debit_mandate, invoice] : nil
        else
          nil
        end
      end.compact

      total_amount_in_cents = data.sum do |e|
        e[1].amount_in_cents_w_vat
      end

      csv = header(data.count)
      csv += "\n"
      csv += data.map { |e| line(e, debit_date) }.join("\n")
      csv += "\n" if data.count > 0
      csv += footer(total_amount_in_cents)
      csv
    end

    def header(count)
      "0;iDocus;;iDocus;;;;#{Date.today};#{count};;;;;;"
    end

    def footer(total_amount_in_cents)
      "9;;;;;;;;%0.2f;" % (total_amount_in_cents/100.0)
    end

    def line(data, debit_date)
      [
        1,
        data[0].user.email,
        nil,
        data[1].organization.try(:name),
        name(data),
        nil,
        nil,
        debit_date,
        amount(data),
        data[0].bic,
        data[0].iban,
        nil,
        nil,
        nil,
        "Prlv iDocus #{formatted_date(data)}",
        nil,
        nil,
        data[1].number,
        nil
      ].join(';')
    end

    def amount(data)
      "%0.2f" % (data[1].amount_in_cents_w_vat/100.0)
    end

    def name(data)
      data[0].user.name.split.map(&:capitalize).join(' ')
    end

    def formatted_date(data)
      time = (data[1].created_at - 1.month)
      I18n.l(time, format: '%B %Y').capitalize
    end
  end
end
