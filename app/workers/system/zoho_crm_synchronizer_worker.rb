class System::ZohoCrmSynchronizerWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform
    UniqueJobs.for 'ZohoCrmSynchronizerWorker' do
      System::ZohoControl.delay_for(1.minutes).send_organizations
      System::ZohoControl.delay_for(15.minutes).send_collaborators #Collaborators must be send 15 minutes after organization's synchronization
    end
  end
end