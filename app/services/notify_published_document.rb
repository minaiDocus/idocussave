class NotifyPublishedDocument
  def initialize(temp_document)
    @temp_document = temp_document
    @user          = temp_document.user
  end

  def execute
    users = [@user, @user.collaborators, @user.prescribers].flatten.compact

    users.each do |user|
      next unless user.notify.published_docs?
      Notifiable.create(notify: user.notify, notifiable: @temp_document, label: 'published')
      next unless user.notify.published_docs_now?
      NotifyPublishedDocumentWorker.perform_in(1.minute, user.id)
    end

    true
  end

  class << self
    def daily
      Notifiable.published_documents.select(:notify_id).distinct.pluck(:notify_id).each do |notify_id|
        notify = Notify.find notify_id
        execute(notify.user.id, false)
      end
    end

    def execute(user_id, send_mail=true)
      user = User.find user_id

      list = user.notify.notifiable_published_documents.includes(notifiable: [:temp_pack]).to_a

      return if list.empty?

      notification = Notification.new
      notification.user        = user
      notification.notice_type = 'published_document'
      notification.title       = list.size == 1 ? 'Nouveau document disponible' : 'Nouveaux documents disponibles'
      notification.url         = Rails.application.routes.url_helpers.account_documents_url ActionMailer::Base.default_url_options

      groups = list.map(&:notifiable).group_by(&:temp_pack)
      if list.size == 1
        message = '1 nouveau document a été ajouté dans '
      else
        message = "#{list.size} nouveaux documents ont été ajoutés dans "
      end
      if groups.size == 1
        message += "le lot suivant : #{groups.first.first.name.sub(' all', '')}"
      else
        message += "les lots suivants :\n\n"
        message += groups.sort_by do |temp_pack, temp_documents|
          temp_pack.name
        end.map do |temp_pack, temp_documents|
          "* #{temp_pack.name.sub(' all', '')} - #{temp_documents.size}"
        end.join("\n")
      end
      notification.message = message

      notification.save
      NotifyWorker.perform_async(notification.id) if send_mail

      list.each(&:delete)
    end
  end
end
