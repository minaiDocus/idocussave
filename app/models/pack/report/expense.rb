# -*- encoding : UTF-8 -*-
class Pack::Report::Expense < ApplicationRecord
  self.inheritance_column = :_type_disabled

  has_one    :observation, class_name: 'Pack::Report::Observation', inverse_of: :expense, dependent: :destroy
  belongs_to :user,                                                 inverse_of: :expenses
  belongs_to :piece,       class_name: 'Pack::Piece',               inverse_of: :expense
  belongs_to :report,      class_name: 'Pack::Report',              inverse_of: :expenses
  belongs_to :organization,                                         inverse_of: :expenses


  default_scope -> { order(position: :asc) }

  scope :pro,      -> { where("origin LIKE ?", "%pro%") }
  scope :perso,    -> { where("origin LIKE ?", "%perso%") }
  scope :normal,   -> { where.not(obs_type: [0]) }
  scope :abnormal, -> { where(obs_type: 0) }



  def to_row(_is_access_url = true)
    [
      piece.cloud_content_object.filename,
      (begin
         date.strftime('%d/%m/%Y')
       rescue
         nil
       end),
      observation.to_s,
      type,
      amount_in_cents_wo_vat,
      vat,
      amount_in_cents_w_vat
    ]
  end


  def add_link(sheet, index, is_access_url)
    sheet.add_hyperlink location: File.join(["https://my.idocus.com", (is_access_url ? piece.get_access_url : piece.cloud_content_object.url)]), ref: sheet.rows[index - 1].cells.second
  end

  def self.distinct_type
    all.distinct.pluck(:type)
  end

  def self.of_type(type)
    where(type: type)
  end

  def self.format_price(price)
    result = price.to_f.round(2).to_s

    (0..result.size).each do |index|
      if result[index] == '.'
        tmp = result[index + 2].nil? ? '0' : result[index + 2]
        result.sub!(result[index..-1], ".#{result[index + 1]}#{tmp}")
      end
    end

    result == '0.00' ? '' : result
  end

  def self.table(sheet, data = [], style = nil)
    sheet.add_row data, style: style
  end

  def self.format(style = nil, options = {})
    style.add_style options
  end

  def self.next_row(sheet, index)
    index.times { table(sheet) }
  end

  def self.last_cell_index(sheet, expenses, first_index, is_access_url, style)
    idx = first_index
    last_cell = 0

    expenses.each_with_index do |expense, _i|
      table(sheet, [''].concat(expense.to_row(is_access_url)), style)
      expense.add_link(sheet, idx, is_access_url)
      idx += 1
      last_cell += 1
    end

    last_cell
  end

  # 12 => index of the first pro row
  # 6 => gap between pro and perso rows

  def self.sum_total_cell(type, first_index = 12 + distinct_type.count, last_index = first_index + pro.count + perso.count + 6)
    total = []
    total <<  "=SUMIF(E#{first_index}:E#{last_index},\"#{type}\",F#{first_index}:F#{last_index})"
    total <<  "=SUMIF(E#{first_index}:E#{last_index},\"#{type}\",G#{first_index}:G#{last_index})"
    total <<  "=SUMIF(E#{first_index}:E#{last_index},\"#{type}\",H#{first_index}:H#{last_index})"
  end

  def self.render_xlsx(is_access_url = true)
    p = Axlsx::Package.new
    p.use_shared_strings = true
    p.use_autowidth = false

    report = first.report

    pack = report.pack

    period = ::I18n.t('date.month_names')[report.created_at.month].capitalize + ' ' + report.created_at.year.to_s

    book_name = pack.name.tr(' ', '_').sub('_all', '')
    wb = p.workbook
    s = wb.styles

    title                = ["Nom de la pièce (url)", 'Date', 'Observations', "Type de dépense", 'HT', 'TVA', 'TTC']

    cell_1               = format(s, alignment: { horizontal: :center }, bg_color: 'F2F2F2')
    cell_2               = format(s, b: true, alignment: { horizontal: :center }, bg_color: 'F2F2F2')
    cell_5               = format(s, bg_color: 'FAC090', b: true)
    last_cell            = format(s, alignment: { horizontal: :right }, format_code: '#,##0.00')

    orange_cell_title    = [0, cell_2, 0, 0, cell_5, 0, 0, last_cell]
    orange_cell_type     = format(s, alignment: { horizontal: :left }, bg_color: 'FDE9D9')
    orange_cell_price    = format(s, alignment: { horizontal: :right }, bg_color: 'FDE9D9', format_code: '#,##0.00')
    orange_dynamic_row   = [0, 0, 0, 0, orange_cell_type, orange_cell_price, orange_cell_price, orange_cell_price]

    price_cell           = format(s, bg_color: 'FAC090', alignment: { horizontal: :right }, format_code: '#,##0.00', b: true)
    owner_row            = [0, cell_1, 0, 0, cell_5, price_cell, price_cell, price_cell]

    default_cell         = [0, cell_1, 0, 0, orange_cell_type, orange_cell_price, orange_cell_price, orange_cell_price]

    green_cell_1         = format(s, bg_color: 'C2D69A', alignment: { horizontal: :right }, format_code: '#,##0.00', b: true)
    green_cell_title     = format(s, bg_color: 'C2D69A', b: true)
    green_pro_title      = format(s, alignment: { horizontal: :right }, format_code: '#,##0.00', bg_color: 'EAF1DD')
    green_cell_content   = format(s, alignment: { horizontal: :left }, format_code: '#,##0.00', bg_color: 'EAF1DD')
    green_each_row       = [0, green_cell_content, green_cell_content, green_cell_content, green_cell_content, green_pro_title, green_pro_title, green_pro_title]
    green_pro_row_title  = [0, green_cell_title, 0, 0, 0, 0, 0, last_cell]
    green_row            = [0, green_cell_title, green_cell_title, green_cell_title, green_cell_title, green_cell_1, green_cell_1, green_cell_1]
    green_sum_row        = [0, 0, 0, 0, 0, green_cell_1, green_cell_1, green_cell_1]

    blue_cell_1          = format(s, bg_color: '93CDDD', alignment: { horizontal: :right }, format_code: '#,##0.00#', b: true)
    blue_cell_title      = format(s, bg_color: '93CDDD', b: true)
    blue_perso_title     = format(s, alignment: { horizontal: :right }, format_code: '#,##0.00', bg_color:  'DBEEF3')
    blue_cell_content    = format(s, alignment: { horizontal: :left }, format_code: '#,##0.00', bg_color:  'DBEEF3')
    blue_each_row        = [0, blue_cell_content, blue_cell_content, blue_cell_content, blue_cell_content, blue_perso_title, blue_perso_title, blue_perso_title]
    blue_perso_row_title = [0, blue_cell_title, 0, 0, 0, 0, 0, last_cell]
    blue_row             = [0, blue_cell_title, blue_cell_title, blue_cell_title, blue_cell_title, blue_cell_1, blue_cell_1, blue_cell_1]
    blue_sum_row         = [0, 0, 0, 0, 0, blue_cell_1, blue_cell_1, blue_cell_1]

    total_sum_row        = [0, 0, 0, 0, 0, price_cell, price_cell, price_cell]

    wb.add_worksheet(name: book_name) do |sheet|
      next_row(sheet, 2)
      table(sheet, ['', 'Notes de frais', '', '', 'Total', '', '', "(en €)"], orange_cell_title)
      table(sheet, ['', '', '', '', ''], [0, cell_1])
      table(sheet, ['', pack.owner.name.to_s, '', '', "Type de dépense", 'HT', 'TVA', 'TTC'], owner_row)

      distinct_type.each_with_index do |type, index|
        result = sum_total_cell(type)
        if index == 0
          table(sheet, ['', '', '', '', type, result].flatten, default_cell)
        elsif index == 1
          table(sheet, ['', period, '', '', type, result].flatten, default_cell)
        else
          table(sheet, ['', '', '', '', type, result].flatten, default_cell)
        end
      end

      total_row = distinct_type.count + 5
      table(sheet, ['', '', '', '', '', "=SUM(F6:F#{total_row})", "=SUM(G6:G#{total_row})", "=SUM(H6:H#{total_row})"], total_sum_row)

      next_row(sheet, 2)

      table(sheet, ['', "Dépenses avec le compte professionnel", '', '', '', '', '', "(en €)"], green_pro_row_title)
      table(sheet)
      table(sheet, [''].concat(title), green_row)

      pro_index = 12 + distinct_type.count

      i = last_cell_index(sheet, pro, pro_index, is_access_url, green_each_row)

      if pro.count > 0
        table(sheet, ['', '', '', '', '', "=SUM(F#{pro_index}:F#{pro_index + i - 1})", "=SUM(G#{pro_index}:G#{pro_index + i - 1})", "=SUM(H#{pro_index}:H#{pro_index + i - 1})"], green_sum_row)
      else
        table(sheet, ['', '', '', '', '', '0.00', '0.00', '0.00'], green_sum_row)
      end

      next_row(sheet, 3)

      table(sheet, ['', "Dépenses avec le compte personnel", '', '', '', '', '', "(en €)"], blue_perso_row_title)
      table(sheet)
      table(sheet, [''].concat(title), blue_row)

      perso_index = 19 + distinct_type.count + pro.count

      j = last_cell_index(sheet, perso, perso_index, is_access_url, blue_each_row)

      if perso.count > 0
        table(sheet, ['', '', '', '', '', "=SUM(F#{perso_index}:F#{perso_index + j - 1})", "=SUM(G#{perso_index}:G#{perso_index + j - 1})", "=SUM(H#{perso_index}:H#{perso_index + j - 1})"], blue_sum_row)
      else
        table(sheet, ['', '', '', '', '', '0.00', '0.00', '0.00'], blue_sum_row)
      end

      sheet.column_widths 10, 37, 10, 30, 22, 10, 10, 10
    end

    p.serialize "/tmp/#{book_name}.xlsx"

    open("/tmp/#{book_name}.xlsx", 'rb', &:read)
  end

  def self.total_amount_in_cents_wo_vat
    sum(:amount_in_cents_wo_vat) || 0
  end

  def self.total_vat
    sum(:vat) || 0
  end

  def self.total_amount_in_cents_w_vat
    sum(:amount_in_cents_w_vat) || 0
  end

  def self.to_rows(period, type, index)
    price = [format_price(total_amount_in_cents_wo_vat), format_price(total_vat), format_price(total_amount_in_cents_w_vat)]

    total = []
    total << if index == 0
               [period.to_s, '', '', type.to_s]
             else
               ['', '', '', type.to_s]
             end
    total << price

    total.flatten
  end

  def self.total_rows(origin)
    [
      '', '', '', '',
      format_price(origin.total_amount_in_cents_wo_vat),
      format_price(origin.total_vat),
      format_price(origin.total_amount_in_cents_w_vat)
    ]
  end

  def self.render_pdf(is_access_url = true)
    report                   = first.report
    pack                     = report.pack

    period                   = ::I18n.t('date.month_names')[report.created_at.month].capitalize + ' ' + report.created_at.year.to_s
    pdf_name                 = pack.name.tr(' ', '_').sub('_all', '')

    title                    = ["Nom de la pièce (url)", 'Date', 'Observations', "Type de dépense", 'HT', 'TVA', 'TTC']

    default_cell             = { align: :center, size: 8, background_color: 'F2F2F2', border_color: 'F2F2F2' }
    global_style             = { border_color: 'FFFFFF', size: 8 }
    total_cell               = { align: :right, size: 8 }

    orange_cell_title        = { background_color: 'FAC090', size: 8, border_color: 'FAC090', font_style: :bold }
    orange_cell_content      = { background_color: 'FDE9D9', border_color: 'FDE9D9', align: :right, font_style: :bold }
    orange_cell_total        = { align: :right, background_color: 'FAC090', size: 8, border_color: 'FAC090', font_style: :bold }

    green_cell_title         = { background_color: 'C2D69A', size: 8, border_color: 'C2D69A', font_style: :bold }
    green_cell_content       = { background_color: 'EAF1DD', border_color: 'EAF1DD', size: 8 }
    green_cell_total         = { align: :right, background_color: 'C2D69A', size: 8, border_color: 'C2D69A', font_style: :bold }

    blue_cell_title          = { background_color: '93CDDD', size: 8, border_color: '93CDDD', font_style: :bold }
    blue_cell_content        = { background_color: 'DBEEF3', size: 8, border_color: 'DBEEF3' }
    blue_cell_total          = { align: :right, background_color: '93CDDD', size: 8, border_color: '93CDDD', font_style: :bold }

    widths                   = [161, 55, 135, 82, 46, 46, 46]

    Prawn::Document.generate("/tmp/#{pdf_name}.pdf", page_size: 'A4', top_margin: 35, left_margin: 11, right_margin: 11) do
      data = ['Notes de frais', '', '', 'Total', '', '', "(en €)"]
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0).style(align: :center, size: 8, background_color: 'F2F2F2', border_color: 'F2F2F2', font_style: :bold)
        cells.column(3).style(orange_cell_title)
        cells.column(6).style(total_cell)
        row(0..-1).height = 6.mm
      end

      data = ['', '', '', '', '', '', '']
      table([data], column_widths: widths, cell_style: { border_color: 'FFFFFF' }) do
        cells.column(0).style(default_cell)
        cells.column(0..-1).height = 3
        row(0..-1).height = 6.mm
      end

      data = [pack.owner.name.to_s, '', '', "Type de dépense", 'HT', 'TVA', 'TTC']
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0).style(default_cell)
        cells.column(3..6).style(orange_cell_title)
        cells.column(4..6).style(total_cell)
        row(0..-1).height = 6.mm
      end

      Pack::Report::Expense.distinct_type.each_with_index do |type, index|
        expense = Pack::Report::Expense.of_type(type)
        data = expense.to_rows(period, type, index)
        table([data], column_widths: widths, cell_style: global_style) do
          index == 0 ? cells.column(0).style(default_cell) : cells.column(0).style(background_color: 'FFFFFF')
          cells.column(4..6).style(align: :right)
          row(0..-1).height = 6.mm
        end
      end

      data = Pack::Report::Expense.total_rows(Pack::Report::Expense)
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(4..6).style(orange_cell_total)
      end

      move_down 40

      data = ["Dépenses avec le compte professionnel", '', '', '', '', '', "(En €)"]
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0).style(green_cell_title)
        cells.column(6).style(total_cell)
      end

      move_down 5

      data = title
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0..-1).style(green_cell_title)
        cells.column(4..6).style(total_cell)
        row(0..-1).height = 6.mm
      end

      Pack::Report::Expense.pro.each do |pr|
        data = pr.to_row(is_access_url)
        (4..6).each { |i| data[i] = Pack::Report::Expense.format_price(data[i]) }
        cell_link = make_cell(content: "<link href='#{File.join(["https://my.idocus.com", (is_access_url ? pr.piece.get_access_url : pr.piece.cloud_content_object.url)])}'>#{data[0]}</link>")
        data[0] = cell_link
        table([data], column_widths: widths, cell_style: { inline_format: true, border_color: 'FFFFFF', size: 8 }) do
          cells.column(4..6).style(total_cell)
          cells.column(0..-1).style(green_cell_content)
          row(0..-1).height = 6.mm
        end
      end

      data = Pack::Report::Expense.total_rows(Pack::Report::Expense.pro)
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0..-1).style(total_cell)
        cells.column(4..6).style(green_cell_title)
        row(0..-1).height = 6.mm
      end

      move_down 40

      data = ["Dépenses avec le compte personnel", '', '', '', '', '', "(En €)"]
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0).style(blue_cell_title)
        cells.column(6).style(total_cell)
        row(0..-1).height = 6.mm
      end

      move_down 5

      data = title
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0..-1).style(blue_cell_title)
        cells.column(4..6).style(total_cell)
        row(0..-1).height = 6.mm
      end

      Pack::Report::Expense.perso.each do |expense|
        data = expense.to_row(is_access_url)
        (4..6).each { |i| data[i] = Pack::Report::Expense.format_price(data[i]) }
        cell_link = make_cell(content: "<link href='#{File.join(["https://my.idocus.com", (is_access_url ? expense.piece.get_access_url : expense.piece.cloud_content_object.url)])}'>#{data[0]}</link>")
        data[0] = cell_link
        table([data], column_widths: widths, cell_style: { inline_format: true, border_color: 'FFFFFF', size: 8 }) do
          cells.column(4..6).style(total_cell)
          cells.column(0..-1).style(blue_cell_content)
          row(0..-1).height = 6.mm
        end
      end

      data = Pack::Report::Expense.total_rows(Pack::Report::Expense.perso)
      table([data], column_widths: widths, cell_style: global_style) do
        cells.column(0..-1).style(total_cell)
        cells.column(4..6).style(blue_cell_total)
        row(0..-1).height = 6.mm
      end
    end

    open("/tmp/#{pdf_name}.pdf", 'rb', &:read)
  end
end
