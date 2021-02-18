class Bridge::ValidateUserEmail
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      access_token =Bridge::Authenticate.new(@user).execute

      BridgeBankin::Connect.validate_email(access_token: access_token).redirect_url
    end
  end
end