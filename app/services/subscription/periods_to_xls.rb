# -*- encoding : UTF-8 -*-
class Subscription::PeriodsToXls
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
      'Pré-affectation',
      'Opération',
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

    @list       = []

    @periods.sort_by(&:end_date).each do |period|
      user            = period.user
      documents       = period.documents.order(created_at: :asc, name: :asc)
      @operation_count = user ? user.operations.where(created_at: period.start_date..period.end_date).count : 0

      if documents.any?
        documents.each do |document|
          @preseizures_count = document.report ? (Pack::Report::Preseizure.unscoped.where(report_id: document.report).where.not(piece_id: nil).count  + document.report.expenses.count) : 0
          fill_data_with(user, period, document)
        end
      else
        @preseizures_count = 0
        fill_data_with(user, period) if user
      end
    end

    range = @with_organization_info ? 0..5 : 0..4
    month_index = @with_organization_info ? 1 : 0
    #list = list.sort do |a, b|
    #  _a = a[range]
    #  _b = b[range]
    #  _a[month_index] = ("%02d" % _a[month_index])
    #  _b[month_index] = ("%02d" % _b[month_index])
    #  _a <=> _b
    #end

    @list.each_with_index do |data, index|
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

    @list = []

    @periods.each do |period|
      billing = Billing::PeriodBilling.new(period)
      period.duration.times do |index|
        month = period.start_date.month + index

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
            period.start_date.year,
            period.user.try(:code).to_s,
            period.user.try(:name).to_s,
            option.group_title,
            option.title,
            format_price(price)
          ]

          @list << data
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
          period.start_date.year,
          period.user.code.to_s,
          period.user.name.to_s,
          'Dépassement',
          '',
          format_price(excesses_amount_in_cents_wo_vat)
        ]

        @list << data
      end
    end

    range = @with_organization_info ? 0..3 : 0..2
    month_index = @with_organization_info ? 1 : 0
    @list = @list.sort do |a, b|
      _a = a[range]
      _b = b[range]
      _a[month_index] = ("%02d" % _a[month_index])
      _b[month_index] = ("%02d" % _b[month_index])
      _a <=> _b
    end

    @list.each_with_index do |data, index|
      sheet2.row(index + 1).replace(data)
    end

    io = StringIO.new('')
    book.write(io)
    io.string
  end

  def format_price(price_in_cents)
    ('%0.2f' % (price_in_cents.round / 100.0)).tr('.', ',')
  end

  def fill_data_with(user=nil, period=nil, document=nil)
    data = []
    data << user.try(:organization).try(:name) if @with_organization_info
    data += [
              period.end_date.month,
              period.start_date.year,
              user.try(:code),
              user.try(:company),
              document.try(:name),
              document.try(:pieces),
              @preseizures_count,
              @operation_count,
              document.try(:scanned_pieces).to_i,
              document.try(:uploaded_pieces).to_i,
              document.try(:dematbox_scanned_pieces).to_i,
              document.try(:retrieved_pieces).to_i,
              document.try(:scanned_sheets).to_i,
              document.try(:pages).to_i,
              document.try(:scanned_pages).to_i,
              document.try(:uploaded_pages).to_i,
              document.try(:dematbox_scanned_pages).to_i,
              document.try(:retrieved_pages).to_i,
              document.try(:paperclips).to_i,
              document.try(:oversize).to_i
            ]
    @list << data
  end
end
