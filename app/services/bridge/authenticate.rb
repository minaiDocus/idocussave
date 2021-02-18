class Bridge::Authenticate
  def initialize(user)
    @user = user
  end

  def execute
    if @user.bridge_account
      BridgeBankin::Authorization.generate_token(email: @user.bridge_account.username, password: @user.bridge_account.password).access_token
    end
  end
end