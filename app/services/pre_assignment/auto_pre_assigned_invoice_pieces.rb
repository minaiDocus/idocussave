# -*- encoding : UTF-8 -*-
class PreAssignment::AutoPreAssignedInvoicePieces
	def self.execute(pieces)
    pieces.each do |piece|
      PreAssignment::AutoPreAssignedInvoicePieces.new(piece).execute
    end

    Billing::UpdatePeriodData.new(pieces.first.user.subscription.current_period).execute
    Billing::UpdatePeriodPrice.new(pieces.first.user.subscription.current_period).execute
  end

  def initialize(piece)
    @piece = piece
    @temp_document = @piece.temp_document
    @invoice = Invoice.select('invoices.*, active_storage_blobs.filename AS filename').joins('join active_storage_attachments ON active_storage_attachments.record_id = invoices.id AND active_storage_attachments.record_type = "Invoice"').joins('join active_storage_blobs ON active_storage_blobs.id = active_storage_attachments.blob_id').where('active_storage_blobs.filename = ?', @temp_document.original_file_name).first
  end

  def execute
    begin
      if @temp_document.present? && @invoice.present? && @piece.preseizures.empty? && !@piece.is_awaiting_pre_assignment?
        # @piece.update(is_awaiting_pre_assignment: true)
        # @piece.processing_pre_assignment unless @piece.pre_assignment_force_processing?

        @piece.waiting_pre_assignment

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
        account_number = !@invoice.organization.subject_to_vat ? '7060900' : '706000'
        
        account = Pack::Report::Preseizure::Account.new
        account.preseizure = preseizure
        account.type       = Pack::Report::Preseizure::Account.get_type('HT') # TTC / HT / TVA
        account.number     = account_number
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
    rescue => e
      System::Log.info('auto_upload_invoice', "#{Time.now} - #{@piece.id} - #{@piece.user.organization.id} - errors : #{e.to_s}")
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