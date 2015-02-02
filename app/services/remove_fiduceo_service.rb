# -*- encoding : UTF-8 -*-
class RemoveFiduceoService
  def initialize(object, notify_error=true)
    if object.is_a? String
      @user = User.find object
    else
      @user = object
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
      addresses = Array(Settings.notify_errors_to)
      if addresses.size > 0
        NotificationMailer.notify(addresses, "[iDocus] Impossible de supprimer Fiduceo pour le client #{@user.code}", '-').deliver
      end
    end
  end
end
