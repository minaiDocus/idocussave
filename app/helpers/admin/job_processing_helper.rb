# frozen_string_literal: true
module Admin::JobProcessingHelper
  def processing_of(job)
    color = "#53b100"

    if job.finished_at.present?
      time_duration = ((job.finished_at - job.started_at)/60).to_i

      color = "#1c57ef"

      if time_duration > 30
        color = "#df2c23"
      elsif time_duration > 20
        color = "#ff5733"
      elsif time_duration > 10
        color = "#f7dc6f"
      end
    end

    elapsed_time = (job.finished_at.present?) ? ((job.finished_at - job.started_at)) : ((Time.now - job.started_at))

    glyphicon('media-record', { color: color } ) + ' ' + Time.at(elapsed_time).utc.strftime("%H:%M:%S")
  end
end