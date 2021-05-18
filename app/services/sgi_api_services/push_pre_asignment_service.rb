# -*- encoding : UTF-8 -*-
class SgiApiServices::PushPreAsignmentService
  class << self
    def process(piece_id, data_pre_assignments)
      piece    = Pack::Piece.where(id: piece_id).first
      return false if not piece

      period   = piece.pack.owner.subscription.current_period
      document = Reporting.find_or_create_period_document(piece.pack, period)
      report   = document.report || create_report(piece.pack, document)

      pre_assignments = get_pre_assignments(piece, report, data_pre_assignments)

      Billing::UpdatePeriodData.new(period).execute
      Billing::UpdatePeriodPrice.new(period).execute

      return false unless data_pre_assignments["process"] == 'preseizure'

      if report.preseizures.not_locked.not_delivered.size > 0
        report.remove_delivered_to
      end

      not_blocked_pre_assignments = pre_assignments.select(&:is_not_blocked_for_duplication)
      not_blocked_pre_assignments = not_blocked_pre_assignments.select{|pres| !pres.has_deleted_piece? }

      if not_blocked_pre_assignments.size > 0
        not_blocked_pre_assignments.each_slice(40) do |preseizures_group|
          PreAssignment::CreateDelivery.new(preseizures_group, ['ibiza', 'exact_online', 'my_unisoft'], is_auto: true).execute
          PreseizureExport::GeneratePreAssignment.new(preseizures_group).execute
        end
        FileDelivery.prepare(report)
        FileDelivery.prepare(piece.pack)
      end
    end

    def create_report(pack, document)
      journal = pack.owner.account_book_types.where(name: pack.name.split[1]).first
      report = Pack::Report.new
      report.organization = pack.owner.organization
      report.user         = pack.owner
      report.pack         = pack
      report.document     = document
      report.type         = journal.try(:compta_type)
      report.name         = pack.name.sub(/ all\z/, '')
      report.save
      report
    end

    def get_pre_assignments(piece, report, datas)
      pre_assignments = []

      _ignored = false

      if datas["process"] == 'preseizure'
        _ignoring_reason = datas['ignore'].to_s.presence

        if _ignoring_reason.present?
          _ignored = true

          Notifications::PreAssignments.new({piece: piece}).notify_pre_assignment_ignored_piece unless piece.is_deleted?
        else
          datas['datas'].each do |data|
            pre_assignments << create_preseizure(piece, report, data)
          end
        end
      elsif datas["process"] == 'expense'
        pre_assignments << create_expense(piece, report, datas['datas'])
      end

      _ignored ? piece.ignored_pre_assignment : piece.processed_pre_assignment

      piece.update(pre_assignment_comment: _ignoring_reason) if piece

      pre_assignments
    end

    def create_preseizure(piece, report, data)
      preseizure = Pack::Report::Preseizure.new
      preseizure.report           = report
      preseizure.piece            = piece
      preseizure.user             = piece.user
      preseizure.organization     = piece.user.organization
      preseizure.piece_number     = data['piece_number']
      preseizure.amount           = data['amount'].try(:to_f)
      preseizure.currency         = data['currency']
      preseizure.unit             = data['unit']
      preseizure.conversion_rate  = data['conversion_rate'].try(:to_f)
      preseizure.third_party      = data['third_party']
      preseizure.date             = data['date'].try(:to_date)
      preseizure.deadline_date    = data['deadline_date'].try(:to_date)
      preseizure.observation      = data['observation']
      preseizure.position         = piece.position
      preseizure.is_made_by_abbyy = data['is_made_by_abbyy']
      preseizure.save

      data['accounts'].each do |data_account|
        account           = Pack::Report::Preseizure::Account.new
        account.type      = Pack::Report::Preseizure::Account.get_type(data_account['type'])
        account.number    = data_account['number']
        account.lettering = data_account['lettering']
        account.save
        preseizure.accounts << account

        entry = Pack::Report::Preseizure::Entry.new
        entry.type   = "Pack::Report::Preseizure::Entry::#{data_account['amount']['type'].to_s.upcase}".constantize
        entry.number = 0
        entry.amount = data_account['amount']["value"].try(:to_f)
        entry.save
        account.entries << entry
        preseizure.entries << entry
      end

      preseizure.update(cached_amount: preseizure.entries.map(&:amount).max)

      unless PreAssignment::DetectDuplicate.new(preseizure).execute
        Notifications::PreAssignments.new({pre_assignment: preseizure}).notify_new_pre_assignment_available unless preseizure.has_deleted_piece?
      end

      preseizure
    end

    def create_expense(piece, report, data)
      obs = data['obs']
      expense                        = Pack::Report::Expense.new
      expense.report                 = report
      expense.piece                  = piece
      expense.user                   = report.user
      expense.organization           = report.organization
      expense.amount_in_cents_wo_vat = data['ht'].try(:to_f)
      expense.amount_in_cents_w_vat  = data['ttc'].try(:to_f)
      expense.vat                    = data['tva'].try(:to_f)
      expense.date                   = data['date'].try(:to_date)
      expense.type                   = data['type']
      expense.origin                 = data['source']
      expense.obs_type               = obs['type'].to_i
      expense.position               = piece.position
      expense.save
      observation         = Pack::Report::Observation.new
      observation.expense = expense
      observation.comment = obs['observation']
      observation.save

      obs['guests'].each do |guest|
        first_name = guest['first_name']
        last_name  = guest['last_name']
        next unless first_name.present? || last_name.present?
        g = Pack::Report::Observation::Guest.new
        g.observation = observation
        g.first_name  = first_name
        g.last_name   = last_name
        g.save
      end

      expense
    end
  end

  def initialize(data_preassignment)
    @data_preassignment = data_preassignment
  end

  def execute
    piece    = Pack::Piece.find @data_preassignment["piece_id"]
    journal  = piece.user.account_book_types.where(name: piece.pack.name.split[1]).first if piece

    errors   = []
    errors << "Piece #{@data_preassignment["piece_id"]} unknown or deleted" if !piece
    errors << "Journal not found" if !journal
    errors << "Piece not awaiting for pre assignment" if !piece.is_awaiting_pre_assignment?
    errors << "Piece #{piece.name} already pre-assigned" if piece && piece.is_already_pre_assigned_with?(@data_preassignment["process"])

    if errors.empty?
      staffing = StaffingFlow.new({ kind: 'preassignment', params: { piece_id: piece.id, data_preassignment: @data_preassignment } }).save
    else
      piece.not_processed_pre_assignment
    end

    { id: @data_preassignment["piece_id"], name: piece.try(:name), errors: errors}
  end
end