class Notifications::Documents < Notifications::Notifier
  def initialize(arguments={})
    super
  end

  def notify_document_being_processed
    users = []
    if @arguments[:sender]
      users << @arguments[:sender]
      users += @arguments[:user].prescribers
      users.uniq!
      users.compact!
    end

    users.each do |user|
      next unless user.notify&.document_being_processed
      Notifiable.create(notify: user.notify, notifiable: @arguments[:temp_document], label: 'processing')

      list = user.notify.notifiable_document_being_processed.includes(notifiable: [:temp_pack]).to_a

      return if list.empty?

      notification_message = if list.size == 1
        "1 nouveau document a été reçu et est en cours de traitement pour le lot suivant : #{list.first.notifiable.temp_pack.name.sub(' all', '')}"
      else
        groups = list.map(&:notifiable).compact.group_by(&:temp_pack)
        message = "#{list.size} nouveaux documents ont été reçus et sont en cours de traitement pour "
        message += groups.size == 1 ? "le lot suivant :\n\n" : "les lots suivants :\n\n"
        message += groups.sort_by do |temp_pack, temp_documents|
          temp_pack.name
        end.map do |temp_pack, temp_documents|
          "* #{temp_pack.name.sub(' all', '')} - #{temp_documents.size}"
        end.join("\n")
        message
      end

      create_notification({
        url: Rails.application.routes.url_helpers.account_documents_url(ActionMailer::Base.default_url_options),
        user: user,
        notice_type: 'document_being_processed',
        title: 'Traitement de document',
        message: notification_message}, true)

      list.each(&:delete)
    end

    true
  end

  def notify_new_scaned_documents
    period = @arguments[:user].periods.order(start_date: :desc).first
    total = period.scanned_sheets + @arguments[:new_count]

    users = [@arguments[:user]]
    users += @arguments[:user].manager ? [@arguments[:user].manager.user] : @arguments[:user].organization.admins

    users.compact.each do |user|
      return unless user.notify.new_scanned_documents

      if user == @arguments[:user]
        period_name = Period.period_name(period.duration, 0, period.start_date.to_time)
        message = "Le total des documents papier envoyés pour la période #{period_name} est de : #{total}."
      else
        message = "Le total des documents papier envoyés par #{@arguments[:user].info} cette période est : #{total}."
      end

      create_notification({
        url:         Rails.application.routes.url_helpers.account_paper_processes_url(ActionMailer::Base.default_url_options),
        user:        user,
        notice_type: 'new_scanned_documents',
        title:       'Nouveau document papier reçu',
        message:     message
      }, false)
    end
  end

  def notify_published_document
    users = [@arguments[:user], @arguments[:user].collaborators, @arguments[:user].prescribers].flatten.compact

    users.each do |user|
      next unless user.notify.try(:published_docs?)
      Notifiable.create(notify: user.notify, notifiable: @arguments[:temp_document], label: 'published')
      next unless user.notify.try(:published_docs_now?)
      published_document_for(user)
    end

    true
  end

  def notify_published_document_daily
    Notifiable.published_documents.select(:notify_id).distinct.pluck(:notify_id).each do |notify_id|
      notify = Notify.find notify_id
      published_document_for(notify.user)
    end
  end

  def notify_updated(start_at, end_at)
    to_be_notified = {}
    packs = updated_packs(start_at, end_at)

    packs.each do |pack|
      ([pack.owner] + pack.owner.group_prescribers + pack.owner.collaborators).each do |user|
        if user.notify.try(:published_docs_delayed?)
          to_be_notified[user] ||= []
          to_be_notified[user] << pack
        end
      end
    end

    to_be_notified.each do |user, packs|
      PackMailer.new_document_available(user, packs, start_at.to_i, end_at.to_i).deliver_later
    end

    Pack.where(id: packs.map(&:id)).update_all(is_update_notified: true)
  end

  def notify_pending
    ReminderEmail.deliver
  end

  private

  def published_document_for(user)
    list = user.notify.notifiable_published_documents.includes(notifiable: [:temp_pack]).to_a

    return if list.empty?

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

    create_notification({
      url:         Rails.application.routes.url_helpers.account_documents_url(ActionMailer::Base.default_url_options),
      user:        user,
      notice_type: 'published_document',
      title:       list.size == 1 ? 'Nouveau document disponible' : 'Nouveaux documents disponibles',
      message:     message
    }, @arguments[:send_mail])

    list.each(&:delete)
  end

  def updated_packs(start_at, end_at)
    Pack.not_notified_update.select do |pack|
      pack.pages.where("created_at >= ? AND created_at <= ?", start_at, end_at).count > 0
    end
  end
end