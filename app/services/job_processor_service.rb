# -*- encoding : UTF-8 -*-
class JobProcessorService
  def self.execute
    new().execute
  end

  def execute
    job_processing_release_lock

    digest_uniq_job
  end

  private

  def job_processing_release_lock
    job_pass_unlocked_1h = %w[DocumentNotification RetrieverNotification ScansNotDeliveredNotification NotifyPaperQuotaReachedWorker NotifyPublishedDocumentDaily NotifyPreAssignmentDeliveryFailureDaily NotifyPreAssignmentExport RemoveOldestRetrievedData NotifyProcessedRequests JobProcessorWorker SendToGrouping]

    job_pass_unlocked_2h = %w[PublishDocument McfProcessor]

    job_pass_unlocked_8h = %w[UpdateAccountingPlan_all ImportFromDropbox ImportFromAllFTP InitializeIbizaboxImport]

    JobProcessing.not_finished.select(:name).distinct.each do |job|
      jobs = JobProcessing.where(name: job.name).order(started_at: :desc)
      job_processing  = jobs.first

      time_duration = ((Time.now - job_processing.started_at)/3600).round

      job_pass_name = job_processing.name.split(/-|_/)[0]

      job_test_1h = job_pass_unlocked_1h.include?(job_pass_name) && time_duration >= 1
      job_test_2h = job_pass_unlocked_2h.include?(job_pass_name) && time_duration >= 2
      job_test_8h = job_pass_unlocked_8h.include?(job_pass_name) && time_duration >= 8

      if job_test_8h || (!job_test_8h && (time_duration >= 3 || job_test_2h || job_test_1h))
        result = $remote_lock.release_lock job_processing.name

        jobs.each(&:abort)

        logger.info "[JOB PROCESSING ABORTED] -- #{job_processing.id}-#{job_processing.name} => Success (#{result} - Nb : #{jobs.size})"
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

      logger.info "[JOB PROCESSING KILLED] -- #{uniq_job_id} => Success"
    end
  end

  def logger
    @logger ||= Logger.new("#{Rails.root}/log/#{Rails.env}_job_processing.log")
  end
end