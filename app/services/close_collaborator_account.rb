# -*- encoding : UTF-8 -*-
class CloseCollaboratorAccount
  def initialize(collaborator)
    @collaborator = collaborator
  end

  def execute
    @collaborator.subscription.try(:destroy)
    @collaborator.debit_mandate.try(:destroy)
    if @collaborator.composition.present? && File.exist?("#{Rails.root}/files/#{Rails.env}/compositions/#{@collaborator.composition.id}")
      system("rm -r #{Rails.root}/files/#{Rails.env}/compositions/#{@collaborator.composition.id}")
    end
    @collaborator.composition.try(:destroy)
    @collaborator.external_file_storage.try(:destroy)
  end
end