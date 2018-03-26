class NotifyDocumentBeingProcessed
  def initialize(temp_document)
    @temp_document = temp_document
    @sender        = User.find_by_code temp_document.delivered_by
    @user          = temp_document.user
  end

  def execute
    users = []
    if @sender
      users << @sender
      users += @user.prescribers
      users.uniq!
      users.compact!
    end

    users.each do |user|
      next unless user.notify&.document_being_processed
      Notifiable.create(notify: user.notify, notifiable: @temp_document, label: 'processing')
      NotifyDocumentBeingProcessedWorker.perform_in(1.minute, user.id)
    end

    true
  end

  def self.execute(user_id)
    user = User.find user_id

    list = user.notify.notifiable_document_being_processed.includes(notifiable: [:temp_pack]).to_a

    return if list.empty?

    notification = Notification.new
    notification.user        = user
    notification.notice_type = 'document_being_processed'
    notification.title       = 'Traitement de document'
    notification.url         = Rails.application.routes.url_helpers.account_documents_url ActionMailer::Base.default_url_options

    notification.message = if list.size == 1
      "1 nouveau document a été reçu et est en cours de traitement pour le lot suivant : #{list.first.notifiable.temp_pack.name.sub(' all', '')}"
    else
      groups = list.map(&:notifiable).group_by(&:temp_pack)
      message = "#{list.size} nouveaux documents ont été reçus et sont en cours de traitement pour "
      message += groups.size == 1 ? "le lot suivant :\n\n" : "les lots suivants :\n\n"
      message += groups.sort_by do |temp_pack, temp_documents|
        temp_pack.name
      end.map do |temp_pack, temp_documents|
        "* #{temp_pack.name.sub(' all', '')} - #{temp_documents.size}"
      end.join("\n")
      message
    end

    NotifyWorker.perform_async(notification.id) if notification.save

    list.each(&:delete)
  end
end
