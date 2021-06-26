module Cedricom
  class ImportTransactions
    CREDIT_OPERATION_CODES = %w(02 04 05 09 12 13 15 16 17 18 24 25 30 31 32 34 35 37 39 40 45 47 49 55 57 59 63 69 72 73 74 77 78 85 87 97 A1 A2 A3 A4 B5 B6 C2 C3 C5)

    def initialize(reception)
      @reception = reception
    end

    def self.perform
      CedricomReception.to_import.each do |reception|
        new(reception).perform
      end
    end

    def perform
      cfonb_by_line = @reception.content.download.split(/\r\n+/)

      raw_operations = read_cfonb(cfonb_by_line)

      operations = format_operations(raw_operations)

      result = save_operations(operations)

      @reception.update(imported: true,
                  skipped_operations_count: result[:skipped_operations_count],
                  imported_operations_count: result[:imported_operations_count],
                  total_operations_count: result[:total_operations_count])
    end

    private

    def operation_type(line)
      line[0..1]
    end

    def bank_account(line)
      line[2..6] + line[11..15] + line[21..31]
    end

    def currency(line)
      line[16..18]
    end

    def decimals_count(line)
      line[19]
    end

    def operation_code(line)
      line[32..33]
    end

    def date(line)
      line[34..39]
    end

    def value_date(line)
      line[42..47]
    end

    def label(line)
      line[48..78]
    end

    def entry_number(line)
      line[81..87]
    end

    def amount(line)
      line[90..102]
    end

    def amount_last_digit(line)
      line[103..103]
    end

    def operation_reference(line)
      line[104..119]
    end

    def get_last_digit_and_sign(last_digit)
      @sign = nil
      @last_digit = nil

      case last_digit
      when "{"
        @last_digit = "0"
        @sign = "+"
      when "A"
        @last_digit = "1"
        @sign = "+"
      when "B"
        @last_digit = "2"
        @sign = "+"
      when "C"
        @last_digit = "3"
        @sign = "+"
      when "D"
        @last_digit = "4"
        @sign = "+"
      when "E"
        @last_digit = "5"
        @sign = "+"
      when "F"
        @last_digit = "6"
        @sign = "+"
      when "G"
        @last_digit = "7"
        @sign = "+"
      when "H"
        @last_digit = "8"
        @sign = "+"
      when "I"
        @last_digit = "9"
        @sign = "+"
      when "}"
        @last_digit = "0"
        @sign = "-"
      when "J"
        @last_digit = "1"
        @sign = "-"
      when "K"
        @last_digit = "2"
        @sign = "-"
      when "L"
        @last_digit = "3"
        @sign = "-"
      when "M"
        @last_digit = "4"
        @sign = "-"
      when "N"
        @last_digit = "5"
        @sign = "-"
      when "O"
        @last_digit = "6"
        @sign = "-"
      when "P"
        @last_digit = "7"
        @sign = "-"
      when "Q"
        @last_digit = "8"
        @sign = "-"
      when "R"
        @last_digit = "9"
        @sign = "-"
      end

      { last_digit: @last_digit, sign: @sign}
    end

    def format_amount(amount, operation_code, decimals_count, amount_last_digit)
      last_digit_and_sign = get_last_digit_and_sign(amount_last_digit)

      raw_amount = "#{amount}#{last_digit_and_sign[:last_digit]}".to_i

      absolute_amount = (raw_amount.to_f / (10**decimals_count.to_i)).round(2)

      if last_digit_and_sign[:sign] == "-"
        absolute_amount = absolute_amount * -1
      end

      absolute_amount
    end

    def format_date(date)
      Date.strptime(date, '%d%m%y')
    end

    def format_label(label)
      label.squeeze(' ').rstrip
    end

    def customer_bank_account(bank_account)
      BankAccount.ebics_enabled.where("number LIKE ?", "%#{bank_account}%").first
    end

    def read_cfonb(cfonb_by_line)
      raw_operations = []

      cfonb_by_line.each do |line|
        raw_operations << {
          date: date(line),
          label: label(line),
          amount: amount(line),
          currency: currency(line),
          value_date: value_date(line),
          bank_account: bank_account(line),
          entry_number: entry_number(line),
          operation_type: operation_type(line),
          operation_code: operation_code(line),
          decimals_count: decimals_count(line),
          amount_last_digit: amount_last_digit(line),
          operation_reference: operation_reference(line)
        }
      end

      raw_operations
    end

    def format_operations(raw_operations)
      operations = []

      raw_operations.each do |raw_operation|
        if raw_operation[:operation_type] == "04"
          amount = format_amount(raw_operation[:amount],
                                 raw_operation[:operation_code],
                                 raw_operation[:decimals_count],
                                 raw_operation[:amount_last_digit])

          operations << {
            date: format_date(raw_operation[:date]),
            value_date: format_date(raw_operation[:value_date]),
            amount: amount,
            currency: raw_operation[:currency],
            long_label: format_label(raw_operation[:label]),
            short_label: format_label(raw_operation[:label]),
            bank_account: raw_operation[:bank_account]
          }
        elsif raw_operation[:operation_type] == "05"
          operations.last[:long_label] = operations.last[:long_label] + " - #{format_label(raw_operation[:label])}"
        end
      end

      operations
    end

    def save_operation(bank_account, cedricom_operation)
      operation = Operation.new

      operation.user   = bank_account.user
      operation.date   = cedricom_operation[:date]
      operation.amount = cedricom_operation[:amount]
      operation.label  = cedricom_operation[:long_label]
      operation.api_name     = 'cedricom'
      operation.value_date   = cedricom_operation[:value_date]
      operation.organization = bank_account.user.organization
      operation.bank_account = bank_account
      operation.cedricom_reception = @reception
      operation.currency = case cedricom_operation[:currency_code]
                            when 'EUR'
                              @operation.currency = { id: 'EUR', symbol: '€', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Euro'}
                            when 'USD'
                              @operation.currency = { id: 'USD', symbol: '$', prefix: true, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'US Dollar'}
                            when 'GBP'
                              @operation.currency = { id: 'GBP', symbol: '£', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'British Pound Sterling'}
                            when 'CHF'
                              @operation.currency = { id: 'CHF', symbol: 'CHF', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'Swiss Franc'}
                            when 'ZAR'
                              @operation.currency = { id: 'ZAR', symbol: 'R', prefix: false, crypto: false, precision: 2, marketcap: nil, datetime: nil, name: 'South African Rand'}
                            end

      operation.save!

      if operation.persisted?
        operation.update(api_id: operation.id)
      end

      operation
    end

    def save_operations(operations)
      result = { imported_operations_count: 0, total_operations_count: operations.count, skipped_operations_count: 0}

      operations.each do |operation|
        bank_account = customer_bank_account(operation[:bank_account])
        next unless bank_account

        if operation[:date] <= bank_account.ebics_enabled_starting
          result[:skipped_operations_count] = result[:skipped_operations_count] + 1
          next
        end

        customer_operation = save_operation(bank_account, operation)

        if customer_operation
          result[:imported_operations_count] = result[:imported_operations_count] + 1
        end
      end

      result
    end
  end
end