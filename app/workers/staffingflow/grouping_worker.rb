class Staffingflow::GroupingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform
    UniqueJobs.for 'staffing_flow_grouping' do
      StaffingFlow.ready_grouping.each do |sf|
        sleep(3)
        next if StaffingFlow.processing_grouping.count > 3 #MAXIMUM THREAD (Concurent job)

        Staffingflow::GroupingWorker::Launcher.delay.process(sf.id)
      end
    end
  end

  class Launcher
    def self.process(staffing_id)
      UniqueJobs.for "staffing_flow_grouping-#{staffing_id}" do
        sf = StaffingFlow.find(staffing_id)
        params = sf.params
        SgiApiServices::GroupDocument.processing(params[:json_content], params[:temp_document_ids], params[:temp_pack_id]) if sf.processing
        sf.processed
      end
    end
  end
end