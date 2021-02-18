class Bridge::ValidateProItems
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      BridgeBankin::Connect.validate_pro_items(access_token: access_token).redirect_url
    end
  end
end