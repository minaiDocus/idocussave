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

    glyphicon('media-record', { color: color } )
  end
end