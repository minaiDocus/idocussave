# -*- encoding : UTF-8 -*-
class Report::GlobalToXls
  def initialize(year)
    @year = year
  end

  def execute
    lines = Organization.billed_for_year(@year).order(name: :asc).map do |organization|
      line = [organization.name]
      customer_ids = organization.customers.pluck(:id)

      12.times.each do |index|
        time = Time.local(@year, index + 1, 15)
        line += Organization::MonthlyReport.new(organization.id, customer_ids, time).execute
      end

      line
    end
    write(lines)
  end

private

  def write(lines)
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: 'Reporting'

    month_names = I18n.t('date.month_names').compact.map(&:capitalize)
    headers = ['Organisation'] + month_names.map { |month_name| [month_name, ''] }.flatten
    sheet.row(0).replace headers

    12.times.each do |index|
      position = ((index + 1) * 2 - 1)
      sheet.merge_cells 0, position, 0, position + 1
    end

    lines.each_with_index do |line, index|
      sheet.row(index + 1).replace line
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end
end
