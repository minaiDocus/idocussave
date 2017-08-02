# TODO : need auto test
class ShareAccount
  def initialize(user, params, current_user=nil)
    @user = user
    @params = params
    @authorized_by = current_user || user
  end

  def execute
    @account_sharing = AccountSharing.new
    if guest_collaborator.persisted?
      @account_sharing.account       = @user
      @account_sharing.collaborator  = guest_collaborator
      @account_sharing.organization  = @user.organization
      @account_sharing.authorized_by = @authorized_by
      @account_sharing.is_approved   = true
      if @account_sharing.save
        DropboxImport.changed([@account_sharing.collaborator])
      end
    end
    [guest_collaborator, @account_sharing]
  end

private

  def guest_collaborator
    if @guest_collaborator
      @guest_collaborator
    else
      @guest_collaborator = User.where(is_prescriber: false, email: @params[:email]).first
      @guest_collaborator ||= CreateGuestCollaborator.new(@params, @user.organization).execute
      @guest_collaborator
    end
  end
end
