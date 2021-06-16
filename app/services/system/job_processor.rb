# -*- encoding : UTF-8 -*-
class System::JobProcessor
  def self.execute
    new().execute
  end

  def execute
    job_processing_release_lock

    digest_uniq_job
  end

  private

  def job_processing_release_lock
    job_pass_unlocked_1h = %w[DocumentNotification RetrieverNotification ScansNotDeliveredNotification NotificationsPaperQuotaReachedWorker NotifyPublishedDocumentDaily NotificationsPreAssignmentDeliveryFailureDaily NotifyPreAssignmentExport RemoveOldestRetrievedData NotifyProcessedRequests JobProcessorWorker SendToGrouping]

    job_pass_unlocked_2h = %w[PublishDocument McfProcessor]

    job_pass_unlocked_8h = %w[UpdateAccountingPlan_all ImportFromDropbox ImportFromAllFTP ImportFromIbizabox DeliverPreAssignments PreAssignmentDeliveryXmlBuilder]

    # Default unlock after 3h

    JobProcessing.not_finished.not_killed.select(:name).distinct.each do |job|
      jobs = JobProcessing.where(name: job.name).not_killed.order(started_at: :desc)
      job_processing  = jobs.first

      time_duration = ((Time.now - job_processing.started_at)/3600).to_i

      job_pass_name = job_processing.name.split(/-|_/)[0]

      job_test_1h = job_pass_unlocked_1h.include?(job_pass_name) && time_duration >= 1
      job_test_2h = job_pass_unlocked_2h.include?(job_pass_name) && time_duration >= 2
      job_test_8h = job_pass_unlocked_8h.include?(job_pass_name) && time_duration >= 8

      if job_test_8h || (!job_pass_unlocked_8h.include?(job_pass_name) && (time_duration >= 3 || job_test_2h || job_test_1h))
        result = $remote_lock.release_lock "#{job_processing.name.strip}"

        jobs.each(&:kill)

        System::Log.info('job_processing', "[JOB PROCESSING ABORTED] -- #{job_processing.id}-#{job_processing.name} - started_at : #{job_processing.started_at.to_s} - killed_at : #{Time.now.to_s} => Success (#{result} - Nb : #{jobs.size})")
      end
    end
  end

  def digest_uniq_job
    SidekiqUniqueJobs::Digests.all.each { |d| add_or_delete_on_cache(d) if d.index(':RUN').nil? }
  end

  def add_or_delete_on_cache(uniq_job_id)
    job_state = Rails.cache.read([:job_processing, uniq_job_id])

    if job_state.nil?
      Rails.cache.write([:job_processing, uniq_job_id], "to_kill", expires_in: 10.minutes)
    elsif job_state == 'to_kill'
      SidekiqUniqueJobs::Digests.delete_by_digest uniq_job_id
      Rails.cache.write([:job_processing, uniq_job_id], "killed", expires_in: 1.minutes)

      System::Log.info('job_processing', "[JOB PROCESSING KILLED] -- #{uniq_job_id} - killed_at : #{Time.now.to_s} => Success")
    end
  end

  private

  def clear_all_lock
    JobProcessing.all.select(:name).distinct.each do |job|
      result = $remote_lock.release_lock "#{job.name.strip}"
      p "#{job.name.strip} - #{result.to_s}" if result.to_i > 0
    end

    di = SidekiqUniqueJobs::Digests.all
    di.each{|d| SidekiqUniqueJobs::Digests.delete_by_digest d}

    staffs = StaffingFlow.processing_preassignment
    p "Processing preassignments - #{staffs.size}"
    staffs.each{|st| st.update(state: 'ready')}

    staffs = StaffingFlow.processing_grouping
    p "Processing grouping - #{staffs.size}"
    staffs.each{|st| st.update(state: 'ready')}

    staffs = PreAssignmentDelivery.ibiza.building_data
    p "Building ibiza datas - #{staffs.size}"
    staffs.each{|st| st.update(state: 'pending')}

    staffs = PreAssignmentDelivery.ibiza.sending
    p "Sending ibiza datas - #{staffs.size}"
    staffs.each{|st| st.update(state: 'data_built')}
  end
end