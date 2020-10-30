# Generate a SepaDirectDebit CSV format to import in Slimpay
class Billing::SepaDirectDebitGenerator
  def self.execute(invoice_time, debit_date)
    data = DebitMandate.configured.map do |debit_mandate|
      invoice = debit_mandate.organization.invoices.where(
        "created_at >= ? AND created_at <= ?", invoice_time.beginning_of_month, invoice_time.end_of_month
      ).first

      invoice ? [debit_mandate, invoice] : nil
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

  def self.header(count)
    "0;iDocus;;iDocus;;;;#{Date.today};#{count};;;;;;"
  end

  def self.footer(total_amount_in_cents)
    '9;;;;;;;;%0.2f;' % (total_amount_in_cents / 100.0)
  end

  def self.line(data, debit_date)
    [
      1,
      data[0].clientReference,
      nil,
      data[0].companyName || data[0].organization.name,
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

  def self.amount(data)
    '%0.2f' % (data[1].amount_in_cents_w_vat / 100.0)
  end

  def self.name(data)
    [data[0].firstName, data[0].lastName].join(' ')
  end

  def self.formatted_date(data)
    time = (data[1].created_at - 1.month)
    I18n.l(time, format: '%B %Y').capitalize
  end
end
