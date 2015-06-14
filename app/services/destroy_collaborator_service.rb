# -*- encoding : UTF-8 -*-
class DestroyCollaboratorService
  def initialize(collaborator)
    @collaborator = collaborator
  end

  def execute
    @collaborator.subscription.try(:destroy)
    @collaborator.periods.destroy_all
    @collaborator.debit_mandate.try(:destroy)
    if @collaborator.composition.present? && File.exist?("#{Rails.root}/files/#{Rails.env}/compositions/#{@collaborator.composition.id}")
      system("rm -r #{Rails.root}/files/#{Rails.env}/compositions/#{@collaborator.composition.id}")
    end
    @collaborator.composition.try(:destroy)
    @collaborator.remote_files.each do |r|
      FileUtils.rm r.temp_path if File.exist?(r.temp_path)
    end
    if @collaborator.external_file_storage
      @collaborator.external_file_storage.try(:dropbox_basic).try(:destroy)
      @collaborator.external_file_storage.try(:google_doc).try(:destroy)
      @collaborator.external_file_storage.try(:ftp).try(:destroy)
      @collaborator.external_file_storage.try(:box).try(:destroy)
      @collaborator.external_file_storage.destroy
    end
    @collaborator.destroy
  end
end
