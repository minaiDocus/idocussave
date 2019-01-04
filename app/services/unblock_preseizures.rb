class UnblockPreseizures
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
      CreatePreAssignmentDeliveryService.new(pres, ['ibiza', 'exact_online'], is_auto: false).execute
      GeneratePreAssignmentExportService.new(pres).execute
      FileDelivery.prepare(report)
      FileDelivery.prepare(report.pack)
      NotifyUnblockedPreseizure.new(pres.first.user, pres.size, @unblocker, 5.minutes).execute
    end

    count
  end
end
