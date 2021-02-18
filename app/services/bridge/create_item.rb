class Bridge::CreateItem
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      BridgeBankin::Connect.connect_item(access_token: access_token).redirect_url
    end
  end
end