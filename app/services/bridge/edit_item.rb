class Bridge::EditItem
  def initialize(user, retriever)
    @user = user
    @retriever = retriever
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      begin
        BridgeBankin::Connect.edit_item(access_token: access_token, item_id: @retriever.bridge_id).redirect_url if access_token
      rescue => e
        return nil
      end
    end
  end
end