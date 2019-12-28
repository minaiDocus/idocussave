class MigrateStorageWorker
  include Sidekiq::Worker
  sidekiq_options retry: false, unique: :until_and_while_executing

  def perform(class_name, class_id, origin_attribute, target_attribute)
    object = class_name.constantize.find(class_id)

    local_file = object.send(origin_attribute)

    target_file = object.send(target_attribute)

    if File.exists?(local_file.path)
      target_file.attach(io: File.open(local_file.path),
                         filename: object.send("#{origin_attribute}_file_name"),
                         content_type: object.send("#{origin_attribute}_content_type"))
    end
  end
end