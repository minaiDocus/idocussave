# -*- encoding : UTF-8 -*-
class PreAssignment::AutoPreAssignedJefacturePieces
  def self.execute(pieces)
    pieces.each do |piece|
      PreAssignment::AutoPreAssignedJefacturePieces.new(piece).execute
    end

    Billing::UpdatePeriodData.new(pieces.first.user.subscription.current_period).execute
    Billing::UpdatePeriodPrice.new(pieces.first.user.subscription.current_period).execute
  end

  def initialize(piece)
    @piece = piece
    @temp_document = @piece.temp_document
    @raw_presezeizure = Jefacture::Document.get(@temp_document.id)
  end

  def execute
    if @temp_document.present? && @raw_presezeizure['piece_number'] && @piece.preseizures.empty? && !@piece.is_awaiting_pre_assignment?
      # @piece.update(is_awaiting_pre_assignment: true)
      # @piece.processing_pre_assignment unless @piece.pre_assignment_force_processing?

      preseizure = Pack::Report::Preseizure.new
      preseizure.organization     = @piece.user.organization
      preseizure.report           = initialize_report
      preseizure.user             = @piece.user
      preseizure.piece            = @piece
      preseizure.date             = @raw_presezeizure['date']
      preseizure.deadline_date    = @raw_presezeizure['deadline_date']
      preseizure.piece_number     = @raw_presezeizure['piece_number']
      preseizure.position         = @piece.position
      preseizure.currency         = @raw_presezeizure['currency']
      preseizure.unit             = @raw_presezeizure['unit']
      preseizure.third_party      = @raw_presezeizure['third_party']
      preseizure.is_made_by_abbyy = true
      preseizure.save

      @raw_presezeizure['entries'].each do |raw_entry|

        account = Pack::Report::Preseizure::Account.new
        account.preseizure = preseizure
        account.type       = raw_entry['account_type'] # TTC / HT / TVA
        account.number     = raw_entry['account']
        account.save

        entry = Pack::Report::Preseizure::Entry.new
        entry.account    = account
        entry.preseizure = preseizure
        entry.type       = raw_entry['type']
        entry.number     = 0
        entry.amount     = raw_entry['amount'].to_f

        entry.save
      end
      
      if preseizure.persisted?
        System::Log.info('auto_upload_invoice', "#{Time.now} - #{@piece.id} - #{@piece.user.organization} - preseizure persisted")

        @piece.processed_pre_assignment
        # @piece.update(is_awaiting_pre_assignment: false)
        preseizure.update(cached_amount: preseizure.entries.map(&:amount).max)

        unless PreAssignment::DetectDuplicate.new(preseizure).execute
          PreAssignment::CreateDelivery.new(preseizure, ['ibiza', 'exact_online', 'my_unisoft'], is_auto: true).execute
          PreseizureExport::GeneratePreAssignment.new(preseizure).execute

          Notifications::PreAssignments.new({pre_assignment: preseizure}).notify_new_pre_assignment_available
        end
      else
        System::Log.info('auto_upload_invoice', "#{Time.now} - #{@piece.id} - #{@piece.user.organization.id} - errors : #{preseizure.errors.full_messages}")
      end
    end
  end

  private

  def initialize_report
    name = @piece.pack.name.sub(' all', '')
    report = Pack::Report.where(name: name).first

    unless report
      report = Pack::Report.new
      report.organization = @piece.user.organization
      report.user         = @piece.user
      report.type         = 'FLUX'
      report.name         = name
      report.save
    end

    report
  end

  def invoice_number
    @invoice.number.to_i
  end

  def invoice_date
    (@invoice.created_at - 1.month).end_of_month
  end

  def invoice_deadline_date
    "4/#{@invoice.created_at.month}/#{@invoice.created_at.year}".to_date
  end

  def third_party_name
    @invoice.organization.addresses.for_billing.first.try(:company) || @invoice.organization.name
  end

  def amount_ht
    (@invoice.amount_in_cents_w_vat / @invoice.vat_ratio).round
  end

  def amount_ttc
    return @invoice_amount unless @invoice_amount.nil?

    if @invoice.organization.subject_to_vat
      @invoice_amount = @invoice.amount_in_cents_w_vat
    else
      @invoice_amount = (@invoice.amount_in_cents_w_vat / @invoice.vat_ratio).round
    end
  end

  def amount_tva
   return @amount_tva unless @amount_tva.nil?
 
   total = amount_ht

   if @invoice.organization.subject_to_vat
      @amount_tva = (total * @invoice.vat_ratio) - total
    else
      @amount_tva = 0
    end
  end

  def format_price price_in_cents
    price_in_euros = price_in_cents.blank? ? "" : price_in_cents.round/100.0
    ("%0.2f" % price_in_euros)
  end
end