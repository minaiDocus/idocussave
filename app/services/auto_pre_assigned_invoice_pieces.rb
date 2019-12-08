# -*- encoding : UTF-8 -*-
class AutoPreAssignedInvoicePieces
	def self.execute(pieces)
    pieces.each do |piece|
      AutoPreAssignedInvoicePieces.new(piece).execute
    end

    UpdatePeriodDataService.new(pieces.first.user.subscription.current_period).execute
    UpdatePeriodPriceService.new(pieces.first.user.subscription.current_period).execute
  end

  def initialize(piece)
    @piece = piece
    @temp_document = @piece.temp_document
    @invoice = Invoice.where(content_file_name: @temp_document.original_file_name).first if @temp_document.present?
  end

  def execute
    begin
      if @temp_document.present? && @invoice.present?
        @piece.update(is_awaiting_pre_assignment: true)
        @piece.processing_pre_assignment unless @piece.pre_assignment_force_processing?

        preseizure = Pack::Report::Preseizure.new
        preseizure.organization     = @piece.user.organization
        preseizure.report           = initialize_report
        preseizure.user             = @piece.user
        preseizure.piece            = @piece
        preseizure.date             = invoice_date
        preseizure.deadline_date    = invoice_deadline_date
        preseizure.piece_number     = invoice_number
        preseizure.position         = @piece.position
        preseizure.currency         = 'EUR'
        preseizure.unit             = 'EUR'
        preseizure.third_party      = third_party_name
        preseizure.is_made_by_abbyy = true
        preseizure.save

        ### 1 ###
        account = Pack::Report::Preseizure::Account.new
        account.preseizure = preseizure
        account.type       = Pack::Report::Preseizure::Account.get_type('TTC') # TTC / HT / TVA
        account.number     = '9DIV'
        account.save

        entry = Pack::Report::Preseizure::Entry.new
        entry.account    = account
        entry.preseizure = preseizure
        entry.type       = Pack::Report::Preseizure::Entry::DEBIT
        entry.number     = 0
        entry.amount     = format_price amount_ttc
        entry.save

        ### 2 ###
        account = Pack::Report::Preseizure::Account.new
        account.preseizure = preseizure
        account.type       = Pack::Report::Preseizure::Account.get_type('HT') # TTC / HT / TVA
        account.number     = '706000'
        account.save

        entry = Pack::Report::Preseizure::Entry.new
        entry.account    = account
        entry.preseizure = preseizure
        entry.type       = Pack::Report::Preseizure::Entry::CREDIT
        entry.number     = 0
        entry.amount     = format_price amount_ht
        entry.save

        if amount_tva > 0
          ### 3 ###
          account = Pack::Report::Preseizure::Account.new
          account.preseizure = preseizure
          account.type       = Pack::Report::Preseizure::Account.get_type('TVA') # TTC / HT / TVA
          account.number     = '445710'
          account.save

          entry = Pack::Report::Preseizure::Entry.new
          entry.account    = account
          entry.preseizure = preseizure
          entry.type       = Pack::Report::Preseizure::Entry::CREDIT
          entry.number     = 0
          entry.amount     = format_price amount_tva
          entry.save
        end
        
        if preseizure.persisted?
          logger.info "#{Time.now} - #{@piece.id} - #{@piece.user.organization} - preseizure persisted"

          @piece.processed_pre_assignment
          @piece.update(is_awaiting_pre_assignment: false)
          preseizure.update(cached_amount: preseizure.entries.map(&:amount).max)

          unless DetectPreseizureDuplicate.new(preseizure).execute
            CreatePreAssignmentDeliveryService.new(preseizure, ['ibiza', 'exact_online'], is_auto: true).execute
            GeneratePreAssignmentExportService.new(preseizure).execute

            NotifyNewPreAssignmentAvailable.new(preseizure, 5.minutes).execute
          end
        else
          logger.info "#{Time.now} - #{@piece.id} - #{@piece.user.organization.id} - errors : #{preseizure.errors.full_messages}"
        end
      end
    rescue => e
      logger.info "#{Time.now} - #{@piece.id} - #{@piece.user.organization.id} - errors : #{e.to_s}"
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

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_auto_upload_invoice.log")
  end
end