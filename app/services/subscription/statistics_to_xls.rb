# -*- encoding : UTF-8 -*-
class Subscription::StatisticsToXls
  def initialize(statistics)
    @statistics = statistics 
  end

  def execute
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet name: "Reporting Forfaits"

    headers = %w(période organisation code basique var_basique courrier var_courrier box var_box automate var_automate mini var_mini micro var_micro nano var_nano idox var_idox automate_unique var_automate_unique)
    headers += %w(téléversement numérisation dematbox automate clients_actifs nouveaux liste_nouveaux clôturés liste_clôturés)
    sheet.row(0).replace headers

    @statistics.each_with_index do |statistic, index|
      row_number = index + 1
      cells = [
        statistic.month,
        statistic.organization_name,
        statistic.organization_code,
        statistic.options[:basic_package],
        statistic.options[:basic_package_diff].to_i,
        statistic.options[:mail_package],
        statistic.options[:mail_package_diff].to_i,
        statistic.options[:scan_box_package],
        statistic.options[:scan_box_package_diff].to_i,
        statistic.options[:retriever_package],
        statistic.options[:retriever_package_diff].to_i,
        statistic.options[:mini_package],
        statistic.options[:mini_package_diff].to_i,
        statistic.options[:micro_package],
        statistic.options[:micro_package_diff].to_i,
        statistic.options[:nano_package],
        statistic.options[:nano_package_diff].to_i,
        statistic.options[:idox_package],
        statistic.options[:idox_package_diff].to_i,
        statistic.options[:retriever_only_package],
        statistic.options[:retriever_only_package_diff].to_i,
        statistic.consumption[:upload],
        statistic.consumption[:scan],
        statistic.consumption[:dematbox_scan],
        statistic.consumption[:retriever],
        statistic.customers.size,
        statistic.new_customers&.size.to_i,
        statistic.new_customers.try(:join, ' - '),
        statistic.closed_customers&.size.to_i,
        statistic.closed_customers.try(:join, ' - ')
      ]

      sheet.row(row_number).replace cells
      sheet.row(row_number).set_format 0, Spreadsheet::Format.new(number_format: 'MMMYY')
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end
end
