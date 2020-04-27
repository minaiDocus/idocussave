# -*- encoding : UTF-8 -*-
class DataVerificator::RemoteFileServiceNameSynchronization < DataVerificator::DataVerificator
  def execute
    time = [1.days.ago..Time.now]

    messages = []

    RemoteFile::SERVICE_NAMES.each do |service_name|
      synced_count      = RemoteFile.of_service(service_name).where(updated_at: time).synchronized.count
      not_synced_count  = RemoteFile.of_service(service_name).where(updated_at: time).not_synchronized.count
      cancelled_count   = RemoteFile.of_service(service_name).where(updated_at: time).cancelled.count
      error_messages    = RemoteFile.of_service(service_name).where(updated_at: time).distinct.pluck(:error_message)

      messages << "service_name: #{service_name}, synchronized: #{synced_count}, not_synchronized: #{not_synced_count}, cancelled: #{cancelled_count}, error_message: #{error_messages.join('<br/>').tr(',;', '--')}"
    end

    {
      title: "RemoteFileServiceNameSynchronization",
      type: "table",
      message: messages.join('; ')
    }
  end
end