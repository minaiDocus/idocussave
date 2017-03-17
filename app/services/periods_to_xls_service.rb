# -*- encoding : UTF-8 -*-
class PeriodsToXlsService
  def initialize(periods, with_organization_info = false)
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

    documents = PeriodDocument.where(period_id: @periods.map(&:id)).order(created_at: :asc, name: :asc)

    list = []

    documents.each do |document|
      data = []
      data << document.period.user.try(:organization).try(:name) if @with_organization_info
      data += [
        document.period.end_at.month,
        document.period.start_at.year,
        document.period.user.code,
        document.period.user.company,
        document.name,
        document.pieces,
        document.scanned_pieces,
        document.uploaded_pieces,
        document.dematbox_scanned_pieces,
        document.retrieved_pieces,
        document.scanned_sheets,
        document.pages,
        document.scanned_pages,
        document.uploaded_pages,
        document.dematbox_scanned_pages,
        document.retrieved_pages,
        document.paperclips,
        document.oversized
      ]
      list << data
    end

    range = @with_organization_info ? 0..5 : 0..4
    month_index = @with_organization_info ? 1 : 0
    list = list.sort do |a, b|
      _a = a[range]
      _b = b[range]
      _a[month_index] = ("%02d" % _a[month_index])
      _b[month_index] = ("%02d" % _b[month_index])
      _a <=> _b
    end

    list.each_with_index do |data, index|
      sheet1.row(index + 1).replace(data)
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

    list = []

    @periods.each do |period|
      billing = PeriodBillingService.new(period)
      period.duration.times do |index|
        month = period.start_at.month + index

        excesses_amount_in_cents_wo_vat = billing.data(:excesses_amount_in_cents_wo_vat, month)

        products_amount_in_cents_wo_vat = billing.amount_in_cents_wo_vat(month) - excesses_amount_in_cents_wo_vat

        period.product_option_orders.each do |option|
          data = []
          if @with_organization_info
            data << if period.user
                        period.user.try(:organization).try(:name)
                      else
                        period.organization.try(:name)
                      end
          end

          price = (option.price_in_cents_wo_vat * products_amount_in_cents_wo_vat)
          price /= period.products_price_in_cents_wo_vat if price != 0.0

          data += [
            month,
            period.start_at.year,
            period.user.try(:code).to_s,
            period.user.try(:name).to_s,
            option.group_title,
            option.title,
            format_price(price)
          ]

          list << data
        end

        next unless period.user && excesses_amount_in_cents_wo_vat > 0

        data = []

        if @with_organization_info
          data << if period.user
                      period.user.try(:organization).try(:name)
                    else
                      period.organization.try(:name)
                    end
        end

        data += [
          month,
          period.start_at.year,
          period.user.code.to_s,
          period.user.name.to_s,
          'Dépassement',
          '',
          format_price(excesses_amount_in_cents_wo_vat)
        ]

        list << data
      end
    end

    range = @with_organization_info ? 0..3 : 0..2
    month_index = @with_organization_info ? 1 : 0
    list = list.sort do |a, b|
      _a = a[range]
      _b = b[range]
      _a[month_index] = ("%02d" % _a[month_index])
      _b[month_index] = ("%02d" % _b[month_index])
      _a <=> _b
    end

    list.each_with_index do |data, index|
      sheet2.row(index + 1).replace(data)
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end



  def format_price(price_in_cents)
    ('%0.2f' % (price_in_cents.round / 100.0)).tr('.', ',')
  end
end
