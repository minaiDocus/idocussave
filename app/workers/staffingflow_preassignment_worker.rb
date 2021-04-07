class StaffingflowPreassignmentWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'staffing_flow_preassignment' do
      StaffingFlow.ready_preassignment.each do |sf|
        params = sf.params
        sf.processing
        SgiApiServices::PushPreAsignmentService.process(params[:piece_id], params[:data_preassignment])
        sf.processed
      end
    end
  end
end