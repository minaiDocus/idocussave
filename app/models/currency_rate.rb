class CurrencyRate < ApplicationRecord
  validates_presence_of :exchange_from, :exchange_to, :exchange_rate, :date

  def create!(params)
    new(params).save
  end

  def self.get_exchange_rate(date, from, to)
    return 1 if date.nil? || from.nil? || to.nil? || from == to

    #take the currency_rate of the day if the given date is future
    date = Date.today if date > Date.today

    current_rate = self.of(date, from, to).try(:exchange_rate)

    if current_rate.nil?
      System::CurrencyRate.execute from, date
      current_rate = self.of(date, from, to).try(:exchange_rate) || 1
    end

    current_rate
  end

  def self.get_operation_exchange_rate(operation)
    get_exchange_rate operation.value_date, operation.bank_account.currency, operation.currency['id']
  end

  def self.already_present?(currency, day)
    where(["date = ? AND exchange_from = ?", day, currency]).any?
  end

  def self.lists
    ["USD", "EUR", "GBP", "INR", "AUD", "CAD", "SGD", "CHF", "MYR", "JPY", "CNY", "NZD", "THB", "HUF", "AED",
     "HKD", "MXN", "ZAR", "PHP", "SEK", "IDR", "SAR", "BRL", "TRY", "KES", "KRW", "EGP", "IQD", "NOK", "KWD",
     "RUB", "DKK", "PKR", "ILS", "PLN", "QAR", "XAU", "OMR", "COP", "CLP", "TWD", "ARS", "CZK", "VND", "MAD",
     "JOD", "BHD", "XOF", "LKR", "UAH", "NGN", "TND", "UGX", "RON", "BDT", "PEN", "GEL", "XAF", "FJD", "VEF",
     "BYR", "HRK", "UZS", "BGN", "DZD", "IRR", "DOP", "ISK", "XAG", "CRC", "SYP", "LYD", "JMD", "MUR", "GHS",
     "AOA", "UYU", "AFN", "LBP", "XPF", "TTD", "TZS", "ALL", "XCD", "GTQ", "NPR", "BOB", "ZWD", "BBD", "CUC",
     "LAK", "BND", "BWP", "HNL", "PYG", "ETB", "NAD", "PGK", "SDG", "MOP", "NIO", "BMD", "KZT", "PAB", "BAM",
     "GYD", "YER", "MGA", "KYD", "MZN", "RSD", "SCR", "AMD", "SBD", "AZN", "SLL", "TOP", "BZD", "MWK", "GMD",
     "BIF", "SOS", "HTG", "GNF", "MVR", "MNT", "CDF", "STD", "TJS", "KPW", "MMK", "LSL", "LRD", "KGS", "GIP",
     "XPT", "MDL", "CUP", "KHR", "MKD", "VUV", "MRO", "ANG", "SZL", "CVE", "SRD", "XPD", "SVC", "BSD", "XDR",
     "RWF", "AWG", "DJF", "BTN", "KMF", "WST", "SPL", "ERN", "FKP", "SHP", "JEP", "TMT", "TVD", "IMP", "GGP", "ZMW"]
  end


  def self.original_currencies
    [
      ["€", "EUR"], ["$", "USD"], ["$, A$, AU$", "AUD"], ["$, C$", "CAD"], ["Fr., SFr, FS", "CHF"], ["¥" , "JPY"],
      ["$, NZ$" ,"NZD"], ["£", "GBP"], ["kr", "SEK"], ["kr", "DKK"], ["kr", "NOK"], ["$, S$", "SGD"], ["Kč", "CZK"],
      ["$, HK$", "HKD"], ["$, Mex$", "MXN"], ["zł", "PLN"], ["₽", "RUB"], ["₺", "TRY"], ["R", "ZAR"], ["¥", "CNH"]
    ]
  end

  def self.of(date, from, to)
    where(["DATE_FORMAT(date, '%Y%m%d') = ? AND exchange_from = ? AND exchange_to = ?", date.strftime('%Y%m%d'), from, to]).first
  end

end
