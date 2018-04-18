class NotifyPreAssignmentIgnoredPieceWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default, retry: false

  def perform(user_id)
    UniqueJobs.for "NotifyPreAssignmentIgnoredPiece-#{user_id}" do
      NotifyPreAssignmentIgnoredPiece.execute(user_id)
    end
  end
end
