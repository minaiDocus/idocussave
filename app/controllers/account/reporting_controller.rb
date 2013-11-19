# -*- encoding : UTF-8 -*-
class Account::ReportingController < Account::AccountController
  layout 'inner', :only => %w(show)

  before_filter :load_user_and_role

  def show
    @year = !params[:year].blank? ? params[:year].to_i : Time.now.year

    if @user.is_prescriber && @user.organization
      @users = @user.customers.asc(:code)
      @subscriptions = ::Scan::Subscription.any_in(user_id: @users.map(&:_id))
    else
      @users = [@user]
      @subscriptions = @user.scan_subscriptions
    end
    @periods = ::Scan::Period.any_in(:subscription_id => @subscriptions.distinct(:_id))
                             .where(:start_at.gte => Time.local(@year,1,1,0,0,0),
                                    :end_at.lte   => Time.local(@year,12,31,23,59,59))
                             .entries
    
    respond_to do |format|
      format.html
      format.xls do
        send_data(render_to_xls(@subscriptions,@year), :type=> 'application/vnd.ms-excel', :filename => "reporting_iDocus_#{Time.now.year}#{"%0.2d" % Time.now.month}#{"%0.2d" % Time.now.day}.xls")
      end
    end
  end
  
private

  def render_to_xls subscriptions, year
    periods = []
    subscriptions.each{ |subscription| periods += subscription.periods.select{ |period| period.start_at.year == year } }
    periods = periods.sort { |a,b| a.start_at.month <=> b.start_at.month }
  
    book = Spreadsheet::Workbook.new
    
    # Document
    sheet1 = book.create_worksheet :name => "Production"
    sheet1.row(0).concat ["Mois", "Année", "Code client", "Société", "Nom du document", "Piéces total", "Piéces numérisées", "Piéces versées", "Piéces iDocus'Box", "Piéces automatique", "Feuilles numérisées", "Pages total", "Pages numérisées", "Pages versées", "Pages iDocus'Box", "Pages automatique", "Attache" ,"Hors format"]
    
    nb = 1
    periods.each do |period|
      period.documents.each do |document|
        data = [
                    period.start_at.month,
                    period.start_at.year,
                    period.user.code,
                    period.user.company,
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
    end
    
    # Invoice
    sheet2 = book.create_worksheet :name => "Facturation"
    sheet2.row(0).concat ["Mois", "Année", "Code client", "Nom du client", "Paramètre", "Valeur", "Prix HT"]
    
    nb = 1
    periods.each do |period|
      period.product_option_orders.each do |option|
        data = [
                    period.start_at.month,
                    period.start_at.year,
                    period.user.code,
                    period.user.name,
                    option.group_title,
                    option.title,
                    format_price_00(option.price_in_cents_wo_vat)
                  ]
        sheet2.row(nb).replace(data)
        nb += 1
      end
      data = [
                  period.start_at.month,
                  period.start_at.year,
                  period.user.code,
                  period.user.name,
                  "Dépassement",
                  "",
                  format_price_00(period.price_in_cents_of_total_excess)
                ]
      sheet2.row(nb).replace(data)
      nb += 1
    end
    
    io = StringIO.new('')
    book.write(io)
    io.string
  end
end
