# -*- encoding : UTF-8 -*-
class PeriodsToXlsService
  def initialize(periods, with_organization_info=false)
    @periods = periods
    @with_organization_info = with_organization_info
  end

  def execute
    book = Spreadsheet::Workbook.new

    # Document
    sheet1 = book.create_worksheet name: 'Production'

    headers = []
    headers << 'Organisation' if @with_organization_info
    headers += [
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
    sheet1.row(0).concat headers

    nb = 1

    documents = Scan::Document.where(:period_id.in => @periods.map(&:id)).asc([:created_at, :name]).entries
    documents = documents.sort do |a, b|
      _a = []
      _a << a.period.user.try(:organization).try(:name) if @with_organization_info
      _a += [
        a.period.start_at.strftime('%Y%m'),
        a.period.user.code,
        a.name
      ]
      _a = _a.join('_')

      _b = []
      _b << b.period.user.try(:organization).try(:name) if @with_organization_info
      _b += [
        b.period.start_at.strftime('%Y%m'),
        b.period.user.code,
        b.name
      ]
      _b = _b.join('_')

      _a <=> _b
    end

    documents.each do |document|
      data = []
      data << document.period.user.try(:organization).try(:name) if @with_organization_info
      data += [
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

    headers = []
    headers << 'Organisation' if @with_organization_info
    headers += [
      'Mois',
      'Année',
      'Code client',
      'Nom du client',
      'Paramètre',
      'Valeur',
      'Prix HT'
    ]
    sheet2.row(0).concat headers

    nb = 1

    periods = @periods.sort do |a, b|
      _a = []
      _a << (a.user.try(:organization).try(:name) || a.organization.try(:name)) if @with_organization_info
      _a += [a.start_at.strftime('%Y%m'), a.user.try(:code)]
      _a = _a.join('_')

      _b = []
      _b << (b.user.try(:organization).try(:name) || b.organization.try(:name)) if @with_organization_info
      _b += [b.start_at.strftime('%Y%m'), b.user.try(:code)]
      _b = _b.join('_')

      _a <=> _b
    end

    periods.each do |period|
      period.product_option_orders.each do |option|
        data = []
        if @with_organization_info
          if period.user
            data << period.user.try(:organization).try(:name)
          else
            data << period.organization.try(:name)
          end
        end
        data += [
          period.start_at.month,
          period.start_at.year,
          period.user.try(:code),
          period.user.try(:name),
          option.group_title,
          option.title,
          format_price(option.price_in_cents_wo_vat)
        ]
        sheet2.row(nb).replace(data)
        nb += 1
      end
      if period.user
        data = []
        if @with_organization_info
          if period.user
            data << period.user.try(:organization).try(:name)
          else
            data << period.organization.try(:name)
          end
        end
        data += [
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
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def format_price price_in_cents
    ("%0.2f" % (price_in_cents.round/100.0)).gsub('.', ',')
  end
end
