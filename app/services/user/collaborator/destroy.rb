class User::Collaborator::Destroy
  def self.execute(collaborator_id)
    collab = User.find collaborator_id
    new(collab).execute
  end

  def initialize(collaborator)
    @collaborator = collaborator
  end

  def execute
    @collaborator.subscription.try(:destroy)

    # if @collaborator.composition.present? && File.exist?("#{Rails.root}/files/compositions/#{@collaborator.composition.id}")
    #   system("rm -r #{Rails.root}/files/compositions/#{@collaborator.composition.id}")
    # end
    # @collaborator.composition&.destroy

    @collaborator.remote_files.each do |r|
      FileUtils.rm r.temp_path if File.exist?(r.temp_path)
    end

    @collaborator.external_file_storage&.destroy
    @collaborator.destroy
  end
end
