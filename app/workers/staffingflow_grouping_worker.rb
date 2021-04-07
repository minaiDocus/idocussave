class StaffingflowGroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'staffing_flow_grouping' do
      StaffingFlow.ready_grouping.each do |sf|
        params = sf.params
        sf.processing
        SgiApiServices::GroupDocument.processing(params[:json_content], params[:temp_document_ids], params[:temp_pack_id])
        sf.processed
      end
    end
  end
end