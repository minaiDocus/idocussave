class Bridge::OtpItem
  def initialize(user, retriever)
    @user = user
    @retriever = retriever
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      BridgeBankin::Connect.item_sync(access_token: access_token, item_id: @retriever.bridge_id).redirect_url
    end
  end
end