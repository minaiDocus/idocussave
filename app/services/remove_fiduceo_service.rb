# -*- encoding : UTF-8 -*-
### Fiduceo related - remained untouched (or nearly) : to be deprecated soon ###class RemoveFiduceoService
class RemoveFiduceoService
  def initialize(object, notify_error = true)
    @user = if object.is_a?(Integer)
              User.find(object)
            else
              object
            end

    @notify_error = notify_error
  end


  def execute
    if @user.fiduceo_id.present?
      @user.temp_documents.wait_selection.destroy_all
      @user.fiduceo_retrievers.each { |r| FiduceoRetrieverService.destroy(r) }

      notify unless @user.fiduceo_retrievers.count == 0 && FiduceoUser.new(@user).destroy
    end
  end

  private


  def notify
    if @notify_error
      addresses = Array(Settings.first.notify_errors_to)

      unless addresses.empty?
        NotificationMailer.notify(addresses, "[iDocus] Impossible de supprimer Fiduceo pour le client #{@user.code}", '-').deliver_later
      end
    end
  end
end
