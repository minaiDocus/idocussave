# -*- encoding : UTF-8 -*-
class User::Collaborator::CloseAccount
  def initialize(collaborator)
    @collaborator = collaborator
  end


  def execute
    @collaborator.subscription.try(:destroy)

    if @collaborator.composition.present? && File.exist?("#{Rails.root}/files/compositions/#{@collaborator.composition.id}")
      system("rm -r #{Rails.root}/files/compositions/#{@collaborator.composition.id}")
    end

    @collaborator.composition.try(:destroy)

    @collaborator.external_file_storage.try(:destroy)
  end
end
