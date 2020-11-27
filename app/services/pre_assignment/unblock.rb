class PreAssignment::Unblock
  def initialize(preseizure_ids, unblocker)
    @preseizure_ids = preseizure_ids
    @unblocker = unblocker
  end

  def execute
    preseizures = Pack::Report::Preseizure.unscoped.where(id: @preseizure_ids)
    count = preseizures.update_all(is_blocked_for_duplication: false,
                                   duplicate_unblocked_at: Time.now,
                                   duplicate_unblocked_by_user_id: @unblocker.id)
    preseizures.group_by do |preseizure|
      preseizure.report
    end.each do |report, pres|
      PreAssignment::CreateDelivery.new(pres, ['ibiza', 'exact_online', 'my_unisoft'], is_auto: false).execute
      PreseizureExport::GeneratePreAssignment.new(pres).execute
      FileDelivery.prepare(report)
      FileDelivery.prepare(report.pack)
      Notifications::PreAssignments.new({owner: pres.first.user, total: pres.size, unblocker: @unblocker}).notify_unblocked_preseizure
    end

    count
  end
end
