class Bridge::EditItem
  def initialize(user, retriever)
    @user = user
    @retriever = retriever
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      BridgeBankin::Connect.edit_item(access_token: access_token, item_id: @retriever.bridge_id).redirect_url
    end
  end
end