class DocumentNotifier
  class << self
    def notify_updated(start_at, end_at)
      to_be_notified = {}
      packs = updated_packs(start_at, end_at)

      packs.each do |pack|
        ([pack.owner] + pack.owner.group_prescribers + pack.owner.collaborators).each do |user|
          if user.notify.published_docs_delayed?
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

    def updated_packs(start_at, end_at)
      Pack.not_notified_update.select do |pack|
        pack.pages.where("created_at >= ? AND created_at <= ?", start_at, end_at).count > 0
      end
    end
  end
end
