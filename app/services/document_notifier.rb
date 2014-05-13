# -*- encoding : UTF-8 -*-
class DocumentNotifier
  class << self
    def notify_updated
      Pack.observers.disable :all do
        updated_packs.each do |owner, packs|
          if owner.is_document_notifier_active
            PackMailer.new_document_available(owner, packs).deliver
          end
          collaborators = owner.groups.map(&:collaborators).flatten.uniq
          collaborators.each do |collaborator|
            if collaborator.is_document_notifier_active
              PackMailer.new_document_available(collaborator, packs).deliver
            end
          end
          packs.each do |pack|
            pack.timeless.update_attribute(:is_update_notified, true)
          end
        end
      end
    end

    # TODO reimplement me
    def notify_pending
      ReminderEmail.deliver
    end

    def updated_packs
      Pack.not_notified_update.group_by(&:owner)
    end
  end
end
