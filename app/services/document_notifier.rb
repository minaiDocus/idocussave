# -*- encoding : UTF-8 -*-
class DocumentNotifier
  def self.notify_updated(start_at, end_at)
    updated_packs(start_at, end_at).each do |owner, packs|
      if owner.is_document_notifier_active
        PackMailer.new_document_available(owner, packs, start_at.to_i, end_at.to_i).deliver_later
      end

      collaborators = owner.groups.map(&:collaborators).flatten.uniq

      collaborators.each do |collaborator|
        if collaborator.is_document_notifier_active
          PackMailer.new_document_available(collaborator, packs, start_at.to_i, end_at.to_i).deliver_later
        end
      end

      Pack.where(id: packs.map(&:id)).update_all(is_update_notified: true)
    end
  end


  def self.notify_pending
    ReminderEmail.deliver
  end


  def self.updated_packs(start_at, end_at)
    Pack.not_notified_update.select do |pack|
      pack.pages.where("created_at >= ? AND created_at <= ?", start_at, end_at).count > 0
    end.group_by(&:owner)
  end
end
