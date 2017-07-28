module FileDelivery
  def self.prepare(object, options = {})
    if object.class != Pack::Report || !object.organization.try(:ibiza).try(:is_configured?)
      options = { type: FileDelivery::RemoteFile::ALL, force: false, delay: false }.merge(options).with_indifferent_access

      if object.class == Pack
        pack = object
      elsif object.class == Pack::Report
        options[:type] = FileDelivery::RemoteFile::REPORT
        pack = object.pack
      end

      pack.extend RemotePack

      if options[:users].present?
        users = options.delete(:users)

        users.each do |user|
          pack.init_delivery_for(user, options)
        end
      elsif options[:groups].present?
        groups = options.delete(:groups)

        groups.each do |group|
          pack.init_delivery_for(group, options)
        end
      else
        owner = pack.owner

        pack.init_delivery_for(owner, options) if options[:type] != FileDelivery::RemoteFile::REPORT

        if options[:type] != FileDelivery::RemoteFile::REPORT && owner.organization.try(:knowings).try(:ready?)
          pack.init_delivery_for(owner.organization, options.merge(type: FileDelivery::RemoteFile::PIECES_ONLY))
        end

        # Organization's collaborators
        owner.prescribers.each do |prescriber|
          pack.init_delivery_for(prescriber, options)
        end

        # Guest collaborators
        owner.collaborators.each do |collaborator|
          pack.init_delivery_for(collaborator, options)
        end

        owner.groups.each do |group|
          pack.init_delivery_for(group, options) if group.is_dropbox_authorized
        end
      end
    end
  end
end
