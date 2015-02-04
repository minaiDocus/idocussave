# -*- encoding : UTF-8 -*-
class PeriodsToXlsService
  def initialize(periods)
    @periods = periods
  end

  def execute
    book = Spreadsheet::Workbook.new

    # Document
    sheet1 = book.create_worksheet name: 'Production'
    sheet1.row(0).concat [
      'Mois',
      'Année',
      'Code client',
      'Société',
      'Nom du document',
      'Piéces total',
      'Piéces numérisées',
      'Piéces versées',
      'Piéces iDocus\'Box',
      'Piéces automatique',
      'Feuilles numérisées',
      'Pages total',
      'Pages numérisées',
      'Pages versées',
      'Pages iDocus\'Box',
      'Pages automatique',
      'Attache',
      'Hors format'
    ]

    nb = 1

    documents = Scan::Document.where(:period_id.in => @periods.map(&:id)).asc([:created_at, :name]).entries
    documents = documents.sort do |a, b|
      "#{a.period.start_at.year}#{a.period.start_at.month}_#{a.period.user.code}_#{a.name}" <=> "#{b.period.start_at.year}#{b.period.start_at.month}_#{b.period.user.code}_#{b.name}"
    end

    documents.each do |document|
      data = [
        document.period.start_at.month,
        document.period.start_at.year,
        document.period.user.code,
        document.period.user.company,
        document.name,
        document.pieces,
        document.scanned_pieces,
        document.uploaded_pieces,
        document.dematbox_scanned_pieces,
        document.fiduceo_pieces,
        document.scanned_sheets,
        document.pages,
        document.scanned_pages,
        document.uploaded_pages,
        document.dematbox_scanned_pages,
        document.fiduceo_pages,
        document.paperclips,
        document.oversized
      ]
      sheet1.row(nb).replace(data)
      nb += 1
    end

    # Invoice
    sheet2 = book.create_worksheet name: 'Facturation'
    sheet2.row(0).concat [
      'Mois',
      'Année',
      'Code client',
      'Nom du client',
      'Paramètre',
      'Valeur',
      'Prix HT'
    ]

    nb = 1

    periods = @periods.sort do |a, b|
      "#{a.start_at.year}#{a.start_at.month}_#{a.user.code}" <=> "#{b.start_at.year}#{b.start_at.month}_#{b.user.code}"
    end

    periods.each do |period|
      period.product_option_orders.each do |option|
        data = [
          period.start_at.month,
          period.start_at.year,
          period.user.code,
          period.user.name,
          option.group_title,
          option.title,
          format_price(option.price_in_cents_wo_vat)
        ]
        sheet2.row(nb).replace(data)
        nb += 1
      end
      data = [
        period.start_at.month,
        period.start_at.year,
        period.user.code,
        period.user.name,
        'Dépassement',
        '',
        format_price(period.price_in_cents_of_total_excess)
      ]
      sheet2.row(nb).replace(data)
      nb += 1
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def format_price price_in_cents
    ("%0.2f" % (price_in_cents.round/100.0)).gsub('.', ',')
  end
end
