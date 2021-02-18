class Bridge::DeletetItem
  def initialize(user, retriever)
    @user = user
    @retriever = retriever
  end

  def execute
    if @user.bridge_account
      access_token = Bridge::Authenticate.new(@user).execute

      if BridgeBankin::Item.delete(id: @retriever.bridge_id, access_token: access_token)
        @retriever.destroy
      end
    end
  end
end